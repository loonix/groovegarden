package controllers

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/render"

	"groovegarden/database"
	"groovegarden/models"
	"groovegarden/websocket"
)

// Get all songs
func GetSongs(w http.ResponseWriter, r *http.Request) {
	rows, err := database.DB.Query("SELECT id, title, url, votes FROM songs")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var songs []models.Song
	for rows.Next() {
		var song models.Song
		if err := rows.Scan(&song.ID, &song.Title, &song.URL, &song.Votes); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		songs = append(songs, song)
	}
	render.JSON(w, r, songs)
}


func AddSong(w http.ResponseWriter, r *http.Request) {
	var song models.Song
	if err := render.DecodeJSON(r.Body, &song); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	_, err := database.DB.Exec("INSERT INTO songs (title, url, votes) VALUES ($1, $2, 0)", song.Title, song.URL)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Notify clients about the new song
	websocket.NotifyClients("song_added", song)
	render.JSON(w, r, map[string]string{"message": "Song added"})
}


// Vote for a song and notify clients
// Vote for a song and notify clients
func VoteForSong(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")

	// Update the song's vote count
	_, err := database.DB.Exec("UPDATE songs SET votes = votes + 1 WHERE id = $1", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Fetch the updated song details
	var song models.Song
	err = database.DB.QueryRow("SELECT id, title, url, votes FROM songs WHERE id = $1", id).Scan(&song.ID, &song.Title, &song.URL, &song.Votes)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Notify clients about the vote
	websocket.NotifyClients("vote_cast", song)

	render.JSON(w, r, map[string]string{"message": "Vote counted"})
}

