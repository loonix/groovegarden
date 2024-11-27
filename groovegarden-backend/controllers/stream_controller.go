package controllers

import (
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"sync"
)

var (
	currentSongPath string
	isStreaming     bool
	mu              sync.Mutex
)

// StartStream handles starting the stream
func StartStream(w http.ResponseWriter, r *http.Request) {
	mu.Lock()
	defer mu.Unlock()

	if isStreaming {
		http.Error(w, "Stream is already running", http.StatusConflict)
		return
	}

	// Set the current song path (this could come from a queue or DB)
	currentSongPath = "./uploads/ cancao do vai vem.mp3" // Replace with actual song selection logic
	go streamToIcecast(currentSongPath)

	isStreaming = true
	w.Write([]byte("Stream started"))
}

// StopStream handles stopping the stream
func StopStream(w http.ResponseWriter, r *http.Request) {
	mu.Lock()
	defer mu.Unlock()

	if !isStreaming {
		http.Error(w, "No stream is currently running", http.StatusConflict)
		return
	}

	// Kill the FFmpeg process
	if err := exec.Command("pkill", "ffmpeg").Run(); err != nil {
		http.Error(w, "Failed to stop the stream", http.StatusInternalServerError)
		return
	}

	isStreaming = false
	w.Write([]byte("Stream stopped"))
}

func streamToIcecast(filePath string) {
    fmt.Println("Preparing to stream:", filePath)

    // Check if Icecast is running
    if err := exec.Command("pgrep", "icecast").Run(); err != nil {
        fmt.Println("Icecast server is not running. Please start Icecast.")
        return
    }

    // Validate file path
    if _, err := os.Stat(filePath); os.IsNotExist(err) {
        fmt.Printf("File does not exist: %s\n", filePath)
        return
    }

    // Command to stream
    cmd := exec.Command("ffmpeg",
        "-re",
        "-i", filePath,
        "-acodec", "libmp3lame",
        "-f", "mp3",
        "-content_type", "audio/mpeg",
        "icecast://source:mengle@localhost:9000/stream")

    // Log output for debugging
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr

    if err := cmd.Start(); err != nil {
        fmt.Printf("Failed to start FFmpeg: %v\n", err)
        return
    }

    fmt.Println("Streaming started for:", filePath)
    cmd.Wait()

    fmt.Println("Streaming stopped for:", filePath)
    mu.Lock()
    isStreaming = false
    mu.Unlock()
}
