package database

import (
	"fmt"
	"log"
)

// InitializeDatabase creates necessary tables if they don't exist
func InitializeDatabase() error {
	log.Println("Initializing database schema...")
	
	// Create users table with all fields
	_, err := DB.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id SERIAL PRIMARY KEY,
			name VARCHAR(255),
			email VARCHAR(255) UNIQUE NOT NULL,
			account_type VARCHAR(20) NOT NULL DEFAULT 'listener',
			profile_picture TEXT,
			bio TEXT,
			links JSONB,
			music_preferences JSONB,
			location VARCHAR(255),
			date_of_birth VARCHAR(255),
			last_seen TIMESTAMP,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	if err != nil {
		return fmt.Errorf("failed to create users table: %w", err)
	}

	// Create songs table with all required fields
	_, err = DB.Exec(`
		CREATE TABLE IF NOT EXISTS songs (
			id SERIAL PRIMARY KEY,
			title VARCHAR(255) NOT NULL,
			artist VARCHAR(255),
			duration INTEGER NOT NULL DEFAULT 0,
			upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			votes INTEGER DEFAULT 0,
			storage_path VARCHAR(255) NOT NULL DEFAULT '',
			artist_id INTEGER REFERENCES users(id) ON DELETE SET NULL
		)
	`)
	if err != nil {
		return fmt.Errorf("failed to create songs table: %w", err)
	}

	// Create a default artist account if none exists
	_, err = DB.Exec(`
		INSERT INTO users (name, email, account_type)
		SELECT 'Default Artist', 'default@artist.com', 'artist'
		WHERE NOT EXISTS (
			SELECT 1 FROM users WHERE account_type = 'artist'
		)
	`)
	if err != nil {
		log.Printf("Warning: Could not create default artist: %v", err)
		// Non-fatal error, continue
	}

	log.Println("Database schema initialized successfully")
	return nil
}
