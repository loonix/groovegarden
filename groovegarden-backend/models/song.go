package models

import (
	"time"
)

// Song represents a music track in the database
type Song struct {
    ID          int       `json:"id"`
    Title       string    `json:"title"`
    Duration    int       `json:"duration"`
    UploadDate  time.Time `json:"upload_date"`
    Votes       int       `json:"votes"`
    StoragePath string    `json:"storage_path"` 
    ArtistID    *int      `json:"artist_id,omitempty"`
    // This field isn't stored in the database table directly
    // It's populated from the JOIN with users table
    Artist      string    `json:"artist,omitempty"` 
}
