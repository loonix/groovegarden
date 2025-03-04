package controllers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/render"

	"groovegarden/database"
	"groovegarden/models"
	"groovegarden/websocket"
)

// GetSongs retrieves all songs from the database
func GetSongs(w http.ResponseWriter, r *http.Request) {
	// Connect to the database
	db, err := database.GetDB()
	if err != nil {
		http.Error(w, "Database connection error", http.StatusInternalServerError)
		return
	}

	// Simple query that should work with our initialized schema
	rows, err := db.Query(`
		SELECT s.id, s.title, COALESCE(s.artist, u.name, 'Unknown') as artist, 
		       s.duration, s.upload_date, s.votes, s.storage_path, s.artist_id
		FROM songs s
		LEFT JOIN users u ON s.artist_id = u.id
		ORDER BY s.votes DESC
	`)
	
	if err != nil {
		http.Error(w, fmt.Sprintf("Error querying database: %v", err), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Parse the rows into a slice of songs
	songs := []map[string]interface{}{} // Initialize as empty array instead of nil slice
	for rows.Next() {
		var id int
		var title sql.NullString
		var artist sql.NullString
		var storagePath sql.NullString
		var artistID sql.NullInt64
		var duration, votes int
		var uploadDate sql.NullString

		// Scan the row into our variables
		err := rows.Scan(&id, &title, &artist, &duration, &uploadDate, &votes, &storagePath, &artistID)
		if err != nil {
			http.Error(w, fmt.Sprintf("Error scanning row: %v", err), http.StatusInternalServerError)
			return
		}

		// Create a map for the song
		song := map[string]interface{}{
			"id":       id,
			"duration": duration,
			"votes":    votes,
		}
		
		// Handle potentially NULL values
		if title.Valid {
			song["title"] = title.String
		} else {
			song["title"] = ""
		}
		
		if artist.Valid {
			song["artist"] = artist.String
		} else {
			song["artist"] = "Unknown"
		}
		
		if uploadDate.Valid {
			song["upload_date"] = uploadDate.String
		} else {
			song["upload_date"] = ""
		}
		
		if storagePath.Valid {
			song["storage_path"] = storagePath.String
		} else {
			song["storage_path"] = ""
		}
		
		if artistID.Valid {
			song["artist_id"] = artistID.Int64
		}

		songs = append(songs, song)
	}

	// Check for errors from iterating over rows
	if err := rows.Err(); err != nil {
		http.Error(w, fmt.Sprintf("Error iterating over rows: %v", err), http.StatusInternalServerError)
		return
	}

	// Return the songs as JSON
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(songs)
}

// Add a song (legacy endpoint for direct metadata addition)
func AddSong(w http.ResponseWriter, r *http.Request) {
	var song models.Song
	fmt.Println("Received /add request")

	if err := json.NewDecoder(r.Body).Decode(&song); err != nil {
		fmt.Printf("Error decoding JSON: %v\n", err)
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	fmt.Printf("Decoded Song: %+v\n", song)

	// Changed from song.FilePath to song.StoragePath
	_, err := database.DB.Exec("INSERT INTO songs (title, storage_path, votes) VALUES ($1, $2, 0)", song.Title, song.StoragePath)
	if (err != nil) {
		fmt.Printf("Error inserting into DB: %v\n", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	fmt.Println("Song added successfully")
	render.JSON(w, r, map[string]string{"message": "Song added"})
}

// Vote for a song and notify clients
func VoteForSong(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	// Update the song's vote count
	_, err := database.DB.Exec("UPDATE songs SET votes = votes + 1 WHERE id = $1", id)
	if (err != nil) {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Fetch the updated song details - changed from song.FilePath to song.StoragePath
	var song models.Song
	err = database.DB.QueryRow("SELECT id, title, storage_path, votes FROM songs WHERE id = $1", id).Scan(&song.ID, &song.Title, &song.StoragePath, &song.Votes)
	if (err != nil) {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Notify clients about the vote
	websocket.NotifyClients("vote_cast", song)
	render.JSON(w, r, map[string]string{"message": "Vote counted"})
}

// Upload a song file
func UploadSong(w http.ResponseWriter, r *http.Request) {
	// Authenticate user and ensure they are an artist
	userIDValue := r.Context().Value("user_id")
	roleValue := r.Context().Value("role")

	// Validate and assert user_id
	userID, ok := userIDValue.(int)
	if (!ok || userIDValue == nil) {
		http.Error(w, "Unauthorized: Missing or invalid user_id", http.StatusUnauthorized)
		return
	}

	// Validate and assert role
	role, ok := roleValue.(string)
	if (!ok || roleValue == nil) {
		http.Error(w, "Unauthorized: Missing or invalid role", http.StatusUnauthorized)
		return
	}

	if (role != "artist") {
		http.Error(w, "Access denied: only artists can upload songs", http.StatusForbidden)
		return
	}

	// Parse the multipart form
	err := r.ParseMultipartForm(10 << 20) // Limit to 10 MB
	if (err != nil) {
		http.Error(w, "File too large or invalid form data", http.StatusBadRequest)
		return
	}

	// Get the file from the form
	file, handler, err := r.FormFile("song")
	if (err != nil) {
		http.Error(w, "Invalid file upload", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Validate file type based on filename extension
	allowedExtensions := []string{".mp3", ".aac"}
	isValidFile := false
	for _, ext := range allowedExtensions {
		if (len(handler.Filename) > len(ext) && handler.Filename[len(handler.Filename)-len(ext):] == ext) {
			isValidFile = true
			break
		}
	}

	if (!isValidFile) {
		http.Error(w, "Invalid file type. Only MP3 and AAC files are allowed.", http.StatusBadRequest)
		return
	}

	// Save the file to the uploads directory
	uploadDir := "./uploads/"
	if _, err := os.Stat(uploadDir); os.IsNotExist(err) {
		if err := os.MkdirAll(uploadDir, os.ModePerm); err != nil {
			http.Error(w, "Failed to create upload directory", http.StatusInternalServerError)
			return
		}
	}

	filePath := uploadDir + handler.Filename
	dst, err := os.Create(filePath)
	if (err != nil) {
		http.Error(w, "Failed to save file", http.StatusInternalServerError)
		return
	}
	defer dst.Close()

	_, err = io.Copy(dst, file)
	if (err != nil) {
		http.Error(w, "Failed to save file", http.StatusInternalServerError)
		return
	}

	// Save song metadata to the database - fixed variable name typo
	_, err = database.DB.Exec(
		"INSERT INTO songs (title, storage_path, votes, artist_id) VALUES ($1, $2, 0, $3)",
		handler.Filename, filePath, userID,
	)
	if (err != nil) {
		http.Error(w, "Failed to save song metadata", http.StatusInternalServerError)
		return
	}

	// Log successful upload
	log.Printf("Song uploaded successfully by user_id %d: %s", userID, handler.Filename)
	render.JSON(w, r, map[string]string{"message": "Song uploaded successfully", "file_path": filePath})
}

// Stream a song file to the client
func StreamSong(w http.ResponseWriter, r *http.Request) {
	// Get the song ID from the URL parameter
	songID := chi.URLParam(r, "id")

	// Fetch the file path from the database - changed file_path to storage_path
	var filePath string
	err := database.DB.QueryRow("SELECT storage_path FROM songs WHERE id = $1", songID).Scan(&filePath)
	if (err != nil) {
		if err == sql.ErrNoRows {
			http.Error(w, "Song not found", http.StatusNotFound)
			return
		}
		http.Error(w, "Failed to fetch song", http.StatusInternalServerError)
		return
	}

	// Stream the file to the client
	http.ServeFile(w, r, filePath)
}
