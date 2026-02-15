package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"gopkg.in/yaml.v3"
)

// Message represents an inbox message
type Message struct {
	ID        string `yaml:"id"`
	From      string `yaml:"from"`
	Type      string `yaml:"type"`
	Content   string `yaml:"content"`
	Timestamp string `yaml:"timestamp"`
	Read      bool   `yaml:"read"`
}

// Inbox represents the inbox file structure
type Inbox struct {
	Messages []Message `yaml:"messages"`
}

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	cmd := os.Args[1]
	switch cmd {
	case "write":
		if len(os.Args) < 4 {
			fmt.Fprintln(os.Stderr, "Usage: ai-agent-shogun write <target> <message> [type] [from]")
			os.Exit(1)
		}
		target := os.Args[2]
		message := os.Args[3]
		msgType := "message"
		from := "unknown"
		if len(os.Args) > 4 {
			msgType = os.Args[4]
		}
		if len(os.Args) > 5 {
			from = os.Args[5]
		}
		if err := writeInbox(target, message, msgType, from); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}

	case "watch":
		if len(os.Args) < 4 {
			fmt.Fprintln(os.Stderr, "Usage: ai-agent-shogun watch <agent_id> <pane_id>")
			os.Exit(1)
		}
		agentID := os.Args[2]
		paneID := os.Args[3]
		if err := watchInbox(agentID, paneID); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}

	default:
		printUsage()
		os.Exit(1)
	}
}

func printUsage() {
	fmt.Println(`Mini Shogun CLI

Commands:
  write <target> <message> [type] [from]  Send message to agent's inbox
  watch <agent_id> <pane_id>              Watch inbox and send nudges

Examples:
  ai-agent-shogun write karo "タスク完了" report ashigaru1
  ai-agent-shogun watch karo 5`)
}

func getProjectRoot() string {
	// Get executable path
	exe, err := os.Executable()
	if err != nil {
		return "."
	}
	return filepath.Dir(exe)
}

func getInboxPath(agentID string) string {
	root := getProjectRoot()
	return filepath.Join(root, "queue", "inbox", agentID+".yaml")
}

func writeInbox(target, message, msgType, from string) error {
	inboxPath := getInboxPath(target)

	// Ensure directory exists
	if err := os.MkdirAll(filepath.Dir(inboxPath), 0755); err != nil {
		return fmt.Errorf("failed to create inbox directory: %w", err)
	}

	// Lock file
	lockPath := inboxPath + ".lock"
	lockFile, err := os.OpenFile(lockPath, os.O_CREATE|os.O_RDWR, 0644)
	if err != nil {
		return fmt.Errorf("failed to open lock file: %w", err)
	}
	defer lockFile.Close()

	// Acquire exclusive lock
	if err := syscall.Flock(int(lockFile.Fd()), syscall.LOCK_EX); err != nil {
		return fmt.Errorf("failed to acquire lock: %w", err)
	}
	defer syscall.Flock(int(lockFile.Fd()), syscall.LOCK_UN)

	// Read existing inbox
	var inbox Inbox
	data, err := os.ReadFile(inboxPath)
	if err != nil {
		if !os.IsNotExist(err) {
			return fmt.Errorf("failed to read inbox: %w", err)
		}
		inbox = Inbox{Messages: []Message{}}
	} else {
		if err := yaml.Unmarshal(data, &inbox); err != nil {
			return fmt.Errorf("failed to parse inbox: %w", err)
		}
	}

	// Create new message
	now := time.Now()
	newMsg := Message{
		ID:        fmt.Sprintf("msg_%s_%d", now.Format("20060102_150405"), now.UnixNano()%10000),
		From:      from,
		Type:      msgType,
		Content:   message,
		Timestamp: now.Format(time.RFC3339),
		Read:      false,
	}

	inbox.Messages = append(inbox.Messages, newMsg)

	// Write atomically
	newData, err := yaml.Marshal(&inbox)
	if err != nil {
		return fmt.Errorf("failed to marshal inbox: %w", err)
	}

	tmpPath := fmt.Sprintf("%s.tmp.%d", inboxPath, os.Getpid())
	if err := os.WriteFile(tmpPath, newData, 0644); err != nil {
		return fmt.Errorf("failed to write temp file: %w", err)
	}

	if err := os.Rename(tmpPath, inboxPath); err != nil {
		os.Remove(tmpPath)
		return fmt.Errorf("failed to rename temp file: %w", err)
	}

	fmt.Printf("[inbox_write] Sent to %s: %s\n", target, newMsg.ID)
	return nil
}

func watchInbox(agentID, paneID string) error {
	inboxPath := getInboxPath(agentID)

	// Ensure inbox exists
	if err := os.MkdirAll(filepath.Dir(inboxPath), 0755); err != nil {
		return fmt.Errorf("failed to create inbox directory: %w", err)
	}
	if _, err := os.Stat(inboxPath); os.IsNotExist(err) {
		if err := os.WriteFile(inboxPath, []byte("messages: []\n"), 0644); err != nil {
			return fmt.Errorf("failed to initialize inbox: %w", err)
		}
	}

	fmt.Printf("[%s] inbox_watcher started — agent: %s, pane: %s\n",
		time.Now().Format("2006-01-02 15:04:05"), agentID, paneID)

	// Process any existing unread
	processUnread(agentID, paneID)

	// Main loop with fswatch
	timeout := 30 // seconds
	for {
		// Run fswatch with timeout
		cmd := exec.Command("fswatch", "-1", "--event", "Updated", "--event", "Renamed", inboxPath)
		done := make(chan error, 1)

		go func() {
			done <- cmd.Run()
		}()

		select {
		case <-done:
			// File changed
		case <-time.After(time.Duration(timeout) * time.Second):
			// Timeout - kill fswatch and check anyway
			cmd.Process.Kill()
		}

		time.Sleep(300 * time.Millisecond)
		processUnread(agentID, paneID)
	}
}

func processUnread(agentID, paneID string) {
	inboxPath := getInboxPath(agentID)

	data, err := os.ReadFile(inboxPath)
	if err != nil {
		return
	}

	var inbox Inbox
	if err := yaml.Unmarshal(data, &inbox); err != nil {
		return
	}

	unreadCount := 0
	for _, msg := range inbox.Messages {
		if !msg.Read {
			unreadCount++
		}
	}

	if unreadCount > 0 {
		sendWakeup(paneID, unreadCount)
	}
}

func sendWakeup(paneID string, unreadCount int) {
	nudge := fmt.Sprintf("inbox%d", unreadCount)

	fmt.Printf("[%s] [SEND-TEXT] Sending nudge to pane %s: inbox%d\n",
		time.Now().Format("2006-01-02 15:04:05"), paneID, unreadCount)

	// Send text
	cmd := exec.Command("wezterm", "cli", "send-text", "--pane-id", paneID, nudge)
	if err := cmd.Run(); err != nil {
		fmt.Printf("[%s] WARNING: send-text failed: %v\n",
			time.Now().Format("2006-01-02 15:04:05"), err)
		return
	}

	// Send Enter key
	time.Sleep(100 * time.Millisecond)
	enterCmd := exec.Command("wezterm", "cli", "send-text", "--no-paste", "--pane-id", paneID)
	enterCmd.Stdin = strings.NewReader("\r")
	if err := enterCmd.Run(); err != nil {
		fmt.Printf("[%s] WARNING: send Enter failed: %v\n",
			time.Now().Format("2006-01-02 15:04:05"), err)
	}
}
