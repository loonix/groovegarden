package controllers

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/render"

	"groovegarden/database"
)

// ListUploads returns a list of all files in the uploads directory
func ListUploads(w http.ResponseWriter, r *http.Request) {
	uploadDir := "./uploads/"
	files, err := os.ReadDir(uploadDir)
	if err != nil {
		render.JSON(w, r, map[string]interface{}{
			"error":   true,
			"message": fmt.Sprintf("Error listing uploads directory: %v", err),
		})
		return
	}

	fileList := []map[string]interface{}{}
	for _, file := range files {
		info, err := file.Info()
		if err != nil {
			continue
		}
		
		fileData := map[string]interface{}{
			"name": file.Name(),
			"size": info.Size(),
			"path": filepath.Join(uploadDir, file.Name()),
			"time": info.ModTime(),
		}
		fileList = append(fileList, fileData)
	}

	render.JSON(w, r, map[string]interface{}{
		"error": false,
		"count": len(fileList),
		"files": fileList,
	})
}

// FixMissingFiles attempts to create placeholder files for songs with missing files
func FixMissingFiles(w http.ResponseWriter, r *http.Request) {
	// Call the utility function
	FixSongPaths()
	
	render.JSON(w, r, map[string]interface{}{
		"error":   false,
		"message": "Path fixing process initiated. Check server logs for details.",
	})
}

// GetSongDetails gets detailed info about a song from the database
func GetSongDetails(w http.ResponseWriter, r *http.Request) {
	songID := chi.URLParam(r, "id")
	
	var id int
	var title, artist, storagePath string
	var votes, duration int
	
	err := database.DB.QueryRow(
		"SELECT id, title, artist, duration, votes, storage_path FROM songs WHERE id = $1", songID,
	).Scan(&id, &title, &artist, &duration, &votes, &storagePath)
	
	if err != nil {
		render.JSON(w, r, map[string]interface{}{
			"error":   true,
			"message": fmt.Sprintf("Error fetching song: %v", err),
		})
		return
	}
	
	// Check if file exists
	fileInfo, err := os.Stat(storagePath)
	fileExists := err == nil
	
	songDetails := map[string]interface{}{
		"id":          id,
		"title":       title,
		"artist":      artist,
		"duration":    duration,
		"votes":       votes,
		"storagePath": storagePath,
		"fileExists":  fileExists,
	}
	
	if fileExists {
		songDetails["fileSize"] = fileInfo.Size()
		songDetails["modTime"] = fileInfo.ModTime()
	}
	
	render.JSON(w, r, songDetails)
}
