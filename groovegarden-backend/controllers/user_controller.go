package controllers

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/go-chi/render"

	"groovegarden/database"
	"groovegarden/models"
)

// UpsertUserFromOAuth creates or updates a user based on OAuth data
func UpsertUserFromOAuth(user map[string]interface{}) (int, error) {
	var userID int

	query := `
		INSERT INTO users (name, email, account_type, profile_picture, created_at, last_seen)
		VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
		ON CONFLICT (email)
		DO UPDATE SET
			name = $1,
			account_type = $3,
			profile_picture = $4,
			last_seen = CURRENT_TIMESTAMP
		RETURNING id;
	`

	err := database.DB.QueryRow(query, user["name"], user["email"], user["account_type"], user["profile_picture"]).Scan(&userID)
	if err != nil {
		log.Printf("Failed to upsert user: %v", err)
		return 0, err
	}

	return userID, nil
}

// Create or Update a User
func UpsertUser(w http.ResponseWriter, r *http.Request) {
	var user models.User
	err := json.NewDecoder(r.Body).Decode(&user)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	query := `
		INSERT INTO users (name, email, account_type, profile_picture, bio, links, music_preferences, location, date_of_birth, last_seen)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_TIMESTAMP)
		ON CONFLICT (email)
		DO UPDATE SET
			name = $1,
			account_type = $3,
			profile_picture = $4,
			bio = $5,
			links = $6,
			music_preferences = $7,
			location = $8,
			date_of_birth = $9,
			last_seen = CURRENT_TIMESTAMP
		RETURNING id;
	`

	var userID int
	err = database.DB.QueryRow(query, user.Name, user.Email, user.AccountType, user.ProfilePicture, user.Bio, user.Links, user.MusicPreferences, user.Location, user.DateOfBirth).Scan(&userID)
	if err != nil {
		fmt.Printf("Error upserting user: %v\n", err) // Log the exact error
		http.Error(w, "Failed to upsert user: "+err.Error(), http.StatusInternalServerError)

		return
	}

	render.JSON(w, r, map[string]interface{}{
		"message": "User upserted successfully",
		"user_id": userID,
	})
}


// Get User by Email
func GetUserByEmail(w http.ResponseWriter, r *http.Request) {
	email := r.URL.Query().Get("email")
	if email == "" {
		http.Error(w, "Email is required", http.StatusBadRequest)
		return
	}

	query := `SELECT * FROM users WHERE email = $1`
	row := database.DB.QueryRow(query, email)

	var user models.User
	err := row.Scan(&user.ID, &user.Name, &user.Email, &user.AccountType, &user.ProfilePicture, &user.Bio, &user.Links, &user.MusicPreferences, &user.Location, &user.DateOfBirth, &user.CreatedAt, &user.LastSeen)
	if err != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	render.JSON(w, r, user)
}
