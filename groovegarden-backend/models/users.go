package models

type User struct {
	ID               int         `json:"id"`
	Name             string      `json:"name"`
	Email            string      `json:"email"`
	AccountType      string      `json:"account_type"` // 'artist' or 'listener'
	ProfilePicture   string      `json:"profile_picture"`
	Bio              string      `json:"bio"`
	Links            interface{} `json:"links"` // JSON for social media links
	MusicPreferences interface{} `json:"music_preferences"` // JSON for preferences
	Location         string      `json:"location"`
	DateOfBirth      string      `json:"date_of_birth"`
	CreatedAt        string      `json:"created_at"`
	LastSeen         string      `json:"last_seen"`
}
