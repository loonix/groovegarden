package controllers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/render"

	"groovegarden/database"
	"groovegarden/models"
)

// GetUserByID retrieves a user from the database by ID
func GetUserByID(w http.ResponseWriter, r *http.Request) {
	// Log request for debugging
	log.Printf("GetUserByID request received for ID: %s", chi.URLParam(r, "id"))

	// Get user ID from URL parameters
	idParam := chi.URLParam(r, "id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		http.Error(w, "Invalid user ID format", http.StatusBadRequest)
		return
	}

	// Query the database for the user - simplified query to avoid NULL issues
	var user struct {
		ID         int            `json:"id"`
		Name       string         `json:"name"`
		Email      string         `json:"email"`
		AccountType string        `json:"account_type"`
	}

	err = database.DB.QueryRow(
		`SELECT id, name, email, account_type FROM users WHERE id = $1`, id,
	).Scan(&user.ID, &user.Name, &user.Email, &user.AccountType)

	if err == sql.ErrNoRows {
		log.Printf("User with ID %d not found", id)
		http.Error(w, "User not found", http.StatusNotFound)
		return
	} else if err != nil {
		log.Printf("Database error retrieving user %d: %v", id, err)
		http.Error(w, fmt.Sprintf("Database error: %v", err), http.StatusInternalServerError)
		return
	}

	// Map account_type to role for API consistency
	response := map[string]interface{}{
		"id":    user.ID,
		"name":  user.Name,
		"email": user.Email,
		"role":  user.AccountType, // Send 'account_type' as 'role'
	}

	log.Printf("User retrieved successfully: %+v", response)
	render.JSON(w, r, response)
}

// UpsertUserFromOAuth creates or updates a user in the database
func UpsertUserFromOAuth(user map[string]interface{}) (int, error) {
	var userID int
	var role string

	// Check if the user already exists
	err := database.DB.QueryRow(
		"SELECT id, account_type FROM users WHERE email = $1",
		user["email"],
	).Scan(&userID, &role)

	if err == sql.ErrNoRows {
		// Insert new user if not found
		err = database.DB.QueryRow(
			`INSERT INTO users (email, name, account_type, profile_picture, created_at) 
			 VALUES ($1, $2, $3, $4, NOW())
			 RETURNING id`,
			user["email"], user["name"], user["account_type"], user["profile_picture"],
		).Scan(&userID)
		if err != nil {
			return 0, fmt.Errorf("failed to insert new user: %w", err)
		}
		// Use the provided account type for new users
		role = user["account_type"].(string)
	} else if err != nil {
		// Handle other errors
		return 0, fmt.Errorf("failed to query user: %w", err)
	}

	// If the user exists, return the existing role
	user["account_type"] = role
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

	// Update any references to User fields to match the consolidated model
	// For example:
	//
	// user.Bio = userData["bio"].(string)
	// user.Links = userData["links"]
	// user.MusicPreferences = userData["music_preferences"]
	// user.Location = userData["location"].(string)
	// user.DateOfBirth = userData["date_of_birth"].(string)
	// user.LastSeen = time.Now()

	render.JSON(w, r, user)
}
