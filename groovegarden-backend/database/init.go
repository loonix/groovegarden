package database

import (
	"fmt"
	"log"
)

// InitializeDatabase sets up all required tables if they don't exist
func InitializeDatabase() error {
	// Create users table if it doesn't exist
	_, err := DB.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id SERIAL PRIMARY KEY,
			name VARCHAR(255),
			email VARCHAR(255) UNIQUE NOT NULL,
			account_type VARCHAR(50) NOT NULL,
			profile_picture TEXT,
			bio TEXT,
			links JSONB,
			music_preferences JSONB,
			location VARCHAR(255),
			date_of_birth DATE,
			created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP
		)
	`)
	
	if err != nil {
		return fmt.Errorf("failed to create users table: %w", err)
	}
	
	// Create songs table if it doesn't exist
	_, err = DB.Exec(`
		CREATE TABLE IF NOT EXISTS songs (
			id SERIAL PRIMARY KEY,
			title VARCHAR(255) NOT NULL,
			url VARCHAR(255) NOT NULL,
			votes INTEGER DEFAULT 0
		)
	`)
	
	if err != nil {
		return fmt.Errorf("failed to create songs table: %w", err)
	}
	
	log.Println("Database tables initialized successfully")
	return nil
}
