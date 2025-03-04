package models

import (
	"time"
)

// User represents a user in the system, which can be a listener or an artist
type User struct {
	ID               int         `json:"id"`
	Name             string      `json:"name"`
	Email            string      `json:"email"`
	AccountType      string      `json:"account_type"` // 'artist' or 'listener'
	ProfilePicture   string      `json:"profile_picture,omitempty"`
	Bio              string      `json:"bio,omitempty"`
	Links            interface{} `json:"links,omitempty"` // JSON for social media links
	MusicPreferences interface{} `json:"music_preferences,omitempty"` // JSON for preferences
	Location         string      `json:"location,omitempty"`
	DateOfBirth      string      `json:"date_of_birth,omitempty"`
	CreatedAt        time.Time   `json:"created_at"`
	LastSeen         time.Time   `json:"last_seen,omitempty"`
}

// IsArtist returns true if the user is an artist
func (u *User) IsArtist() bool {
	return u.AccountType == "artist"
}
