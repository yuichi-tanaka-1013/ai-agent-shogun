package main

import (
	"context"
	"crypto/rand"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"gopkg.in/yaml.v3"
)

// validAgentIDs is the allowlist of valid agent identifiers
var validAgentIDs = map[string]bool{
	"shogun":   true,
	"karo":     true,
	"ashigaru1": true, "ashigaru2": true, "ashigaru3": true, "ashigaru4": true,
	"ashigaru5": true, "ashigaru6": true, "ashigaru7": true, "ashigaru8": true,
}

// validateAgentID checks that the agent ID is in the allowlist
func validateAgentID(agentID string) error {
	if !validAgentIDs[agentID] {
		return fmt.Errorf("invalid agent ID: %q (allowed: shogun, karo, ashigaru1-8)", agentID)
	}
	return nil
}

// generateMsgID generates a unique message ID using timestamp and random bytes
func generateMsgID() string {
	now := time.Now()
	b := make([]byte, 4)
	rand.Read(b)
	return fmt.Sprintf("msg_%s_%x", now.Format("20060102_150405"), b)
}

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
	case "start":
		if err := startAgents(); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}

	case "stop":
		if err := stopAgents(); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}

	case "write":
		if len(os.Args) < 4 {
			fmt.Fprintln(os.Stderr, "Usage: ai-agent-shogun write <target> <message> [type] [from]")
			os.Exit(1)
		}
		target := os.Args[2]
		if err := validateAgentID(target); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
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
		if err := validateAgentID(agentID); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
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
	fmt.Println(`AI Agent Shogun CLI

Commands:
  start                                   Start agents in current directory
  stop                                    Stop all agents
  write <target> <message> [type] [from]  Send message to agent's inbox
  watch <agent_id> <pane_id>              Watch inbox and send nudges

Examples:
  ai-agent-shogun start
  ai-agent-shogun stop
  ai-agent-shogun write karo "タスク完了" report ashigaru1
  ai-agent-shogun watch karo 5

Environment:
  AI_AGENT_SHOGUN_HOME    Tool home directory (default: ~/.ai-agent-shogun)
  AI_AGENT_SHOGUN_WORKDIR Work directory (default: current directory)`)
}

// getHomeDir returns the tool's home directory (~/.ai-agent-shogun)
func getHomeDir() string {
	if env := os.Getenv("AI_AGENT_SHOGUN_HOME"); env != "" {
		return env
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "."
	}
	return filepath.Join(home, ".ai-agent-shogun")
}

// getWorkDir returns the current work directory
func getWorkDir() string {
	if env := os.Getenv("AI_AGENT_SHOGUN_WORKDIR"); env != "" {
		return env
	}
	// Check if .work_dir file exists in .ai-agent-shogun/ of cwd
	cwd, err := os.Getwd()
	if err != nil {
		return "."
	}
	workDirFile := filepath.Join(cwd, ".ai-agent-shogun", ".work_dir")
	if data, err := os.ReadFile(workDirFile); err == nil {
		return strings.TrimSpace(string(data))
	}
	return cwd
}

// getDataDir returns the data directory for current work session
func getDataDir() string {
	return filepath.Join(getWorkDir(), ".ai-agent-shogun")
}

func getInboxPath(agentID string) string {
	return filepath.Join(getDataDir(), "queue", "inbox", agentID+".yaml")
}

// startAgents launches the agent system
func startAgents() error {
	homeDir := getHomeDir()
	workDir := getWorkDir()

	// Check if start.zsh exists in home directory
	startScript := filepath.Join(homeDir, "start.zsh")
	if _, err := os.Stat(startScript); os.IsNotExist(err) {
		return fmt.Errorf("start.zsh not found in %s. Run 'make install' first", homeDir)
	}

	fmt.Printf("🏯 AI Agent Shogun 起動中...\n")
	fmt.Printf("📂 作業ディレクトリ: %s\n", workDir)
	fmt.Printf("📦 ホームディレクトリ: %s\n", homeDir)

	// Run start.zsh with environment variables
	cmd := exec.Command("zsh", startScript)
	cmd.Dir = workDir
	cmd.Env = append(os.Environ(),
		"AI_AGENT_SHOGUN_HOME="+homeDir,
		"AI_AGENT_SHOGUN_WORKDIR="+workDir,
	)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	return cmd.Run()
}

// stopAgents stops the agent system
func stopAgents() error {
	homeDir := getHomeDir()
	workDir := getWorkDir()

	// Check if stop.zsh exists in home directory
	stopScript := filepath.Join(homeDir, "stop.zsh")
	if _, err := os.Stat(stopScript); os.IsNotExist(err) {
		return fmt.Errorf("stop.zsh not found in %s. Run 'make install' first", homeDir)
	}

	fmt.Printf("🛑 AI Agent Shogun 停止中...\n")

	// Run stop.zsh with environment variables
	cmd := exec.Command("zsh", stopScript)
	cmd.Dir = workDir
	cmd.Env = append(os.Environ(),
		"AI_AGENT_SHOGUN_HOME="+homeDir,
		"AI_AGENT_SHOGUN_WORKDIR="+workDir,
	)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
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
	newMsg := Message{
		ID:        generateMsgID(),
		From:      from,
		Type:      msgType,
		Content:   message,
		Timestamp: time.Now().Format(time.RFC3339),
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

	// Set up signal handling for graceful shutdown
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
	defer stop()

	fmt.Printf("[%s] inbox_watcher started — agent: %s, pane: %s\n",
		time.Now().Format("2006-01-02 15:04:05"), agentID, paneID)

	// Process any existing unread
	processUnread(agentID, paneID)

	// Main loop with fswatch
	timeout := 30 // seconds
	for {
		// Check if shutdown requested
		select {
		case <-ctx.Done():
			fmt.Printf("[%s] inbox_watcher shutting down — agent: %s\n",
				time.Now().Format("2006-01-02 15:04:05"), agentID)
			return nil
		default:
		}

		// Run fswatch with timeout
		cmd := exec.Command("fswatch", "-1", "--event", "Updated", "--event", "Renamed", inboxPath)
		done := make(chan error, 1)

		go func() {
			done <- cmd.Run()
		}()

		select {
		case <-ctx.Done():
			if cmd.Process != nil {
				cmd.Process.Kill()
				cmd.Wait()
			}
			fmt.Printf("[%s] inbox_watcher shutting down — agent: %s\n",
				time.Now().Format("2006-01-02 15:04:05"), agentID)
			return nil
		case <-done:
			// File changed
		case <-time.After(time.Duration(timeout) * time.Second):
			// Timeout - kill fswatch and check anyway
			if cmd.Process != nil {
				cmd.Process.Kill()
				cmd.Wait()
			}
		}

		time.Sleep(300 * time.Millisecond)
		processUnread(agentID, paneID)
	}
}

func processUnread(agentID, paneID string) {
	inboxPath := getInboxPath(agentID)

	// Acquire shared lock for safe reading
	lockPath := inboxPath + ".lock"
	lockFile, err := os.OpenFile(lockPath, os.O_CREATE|os.O_RDWR, 0644)
	if err != nil {
		fmt.Printf("[%s] WARNING: [%s] failed to open lock file: %v\n",
			time.Now().Format("2006-01-02 15:04:05"), agentID, err)
		return
	}
	defer lockFile.Close()

	if err := syscall.Flock(int(lockFile.Fd()), syscall.LOCK_SH); err != nil {
		fmt.Printf("[%s] WARNING: [%s] failed to acquire shared lock: %v\n",
			time.Now().Format("2006-01-02 15:04:05"), agentID, err)
		return
	}
	defer syscall.Flock(int(lockFile.Fd()), syscall.LOCK_UN)

	data, err := os.ReadFile(inboxPath)
	if err != nil {
		fmt.Printf("[%s] WARNING: [%s] failed to read inbox: %v\n",
			time.Now().Format("2006-01-02 15:04:05"), agentID, err)
		return
	}

	var inbox Inbox
	if err := yaml.Unmarshal(data, &inbox); err != nil {
		fmt.Printf("[%s] WARNING: [%s] failed to parse inbox YAML: %v\n",
			time.Now().Format("2006-01-02 15:04:05"), agentID, err)
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
