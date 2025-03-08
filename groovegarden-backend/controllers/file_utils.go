package controllers

import (
	"database/sql"
	"encoding/base64"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"groovegarden/database"
)

// EnsureUploadsDirectory makes sure the uploads directory exists
func EnsureUploadsDirectory() {
	uploadDir := "./uploads/"
	if _, err := os.Stat(uploadDir); os.IsNotExist(err) {
		log.Printf("Creating uploads directory: %s", uploadDir)
		if err := os.MkdirAll(uploadDir, os.ModePerm); err != nil {
			log.Printf("Error creating uploads directory: %v", err)
		} else {
			log.Printf("Uploads directory created successfully")
		}
	} else {
		log.Printf("Uploads directory exists: %s", uploadDir)
	}
}

// SanitizeFilePath ensures the file path is valid and removes any spaces
func SanitizeFilePath(originalPath string) string {
	// Replace spaces with underscores
	sanitized := strings.ReplaceAll(originalPath, " ", "_")
	
	// Get the directory and filename
	dir := filepath.Dir(sanitized)
	filename := filepath.Base(sanitized)
	
	// If the path is just a filename (no directory), prefix with uploads dir
	if dir == "." || dir == "/" {
		return filepath.Join("./uploads", filename)
	}
	
	return sanitized
}

// sanitizeFilename removes invalid characters from a filename
func sanitizeFilename(name string) string {
	// Replace spaces and special characters with underscores
	invalid := []string{" ", "/", "\\", ":", "*", "?", "\"", "<", ">", "|"}
	result := name
	for _, char := range invalid {
		result = strings.ReplaceAll(result, char, "_")
	}
	return result
}

// createValidPlaceholderAudio creates a valid short MP3 file that can be played
// We'll use a pre-generated silent MP3 file embedded as a base64 string
func createValidPlaceholderAudio(path string) error {
	// This is a minimal valid silent MP3 file (about 1 second of silence)
	silentMP3Base64 := "SUQzBAAAAAAAI1RTU0UAAAAPAAADTGF2ZjU4Ljc2LjEwMAAAAAAAAAAAAAAA//tAwAAAAAAAAAAAAAAAAAAAAAAASW5mbwAAAA8AAAABAAADQgD///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////8AAAAATGF2YzU4LjEzAAAAAAAAAAAAAAAAJAQKAAAAAAAAA0LA/mJaAAAAAAAAAAAAAAAAAAAA"
	
	// Decode the base64 string
	silentMP3, err := base64.StdEncoding.DecodeString(silentMP3Base64)
	if err != nil {
		return fmt.Errorf("failed to decode silent MP3: %v", err)
	}
	
	// Write the file
	return os.WriteFile(path, silentMP3, 0644)
}

// FixSongPaths checks all song paths in the database and ensures they're valid
func FixSongPaths() {
	log.Println("Checking and fixing song paths in the database...")
	rows, err := database.DB.Query("SELECT id, title, storage_path FROM songs")
	if err != nil {
		log.Printf("Error querying songs: %v", err)
		return
	}
	defer rows.Close()

	var fixCount int
	for rows.Next() {
		var id int
		var title sql.NullString
		var path sql.NullString

		if err := rows.Scan(&id, &title, &path); err != nil {
			log.Printf("Error scanning row: %v", err)
			continue
		}

		if !path.Valid || path.String == "" {
			log.Printf("Song ID %d has no path", id)
			continue
		}

		// Check if file exists at the given path
		_, err := os.Stat(path.String)
		if err != nil {
			oldPath := path.String
			
			// Try to find the file with different path formats
			found := false
			
			// Original filename alternatives
			filename := filepath.Base(oldPath)
			possiblePaths := []string{
				filepath.Join("./uploads", filename),
				filepath.Join("./uploads", strings.ReplaceAll(filename, " ", "_")),
				filepath.Join("uploads", filename),
				filepath.Join("uploads", strings.ReplaceAll(filename, " ", "_")),
			}
			
			var newPath string
			for _, testPath := range possiblePaths {
				if _, err := os.Stat(testPath); err == nil {
					newPath = testPath
					found = true
					log.Printf("Found file at alternative path: %s", newPath)
					break
				}
			}
			
			// If still not found, create a named placeholder using the song title
			if !found {
				var placeholderName string
				if title.Valid && title.String != "" {
					// Use the song's title for the placeholder
					placeholderName = sanitizeFilename(title.String) + ".mp3"
				} else {
					// Use a generic name with the ID
					placeholderName = fmt.Sprintf("song_%d.mp3", id)
				}
				
				newPath = filepath.Join("./uploads", placeholderName)
				log.Printf("Creating placeholder file for song ID %d: %s", id, newPath)
				
				// Create a valid MP3 file
				if err := createValidPlaceholderAudio(newPath); err != nil {
					log.Printf("Error creating placeholder: %v", err)
					continue
				}
			}

			// Update the path in the database
			log.Printf("Fixing path for song ID %d: %s -> %s", id, oldPath, newPath)
			_, err = database.DB.Exec("UPDATE songs SET storage_path = $1 WHERE id = $2", newPath, id)
			if err != nil {
				log.Printf("Error updating song path: %v", err)
				continue
			}
			fixCount++
		}
	}

	log.Printf("Fixed %d song paths", fixCount)
}