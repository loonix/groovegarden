package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	_ "github.com/lib/pq"
)

// DB is the database connection
// This is the consolidated database connection handling - db.go has been removed
var DB *sql.DB

// GetDB returns the database connection
func GetDB() (*sql.DB, error) {
	if DB == nil {
		if err := Connect(); err != nil {
			return nil, err
		}
	}
	return DB, nil
}

// Connect initializes the database connection
func Connect() error {
	// Get connection parameters from environment variables with fallbacks
	host := os.Getenv("POSTGRES_HOST")
	if host == "" {
		host = "localhost"
	}

	port := os.Getenv("POSTGRES_PORT")
	if port == "" {
		port = "5432"
	}

	// Try multiple username options for PostgreSQL
	// On macOS, the default user is often the system username
	user := os.Getenv("POSTGRES_USER")
	if user == "" {
		// First try with the current OS username (most common on macOS)
		currentUser := os.Getenv("USER") // This will get the current system username on Unix systems
		if currentUser != "" {
			log.Printf("Attempting with system username: %s", currentUser)
			
			// Test connection with system username
			testConnStr := fmt.Sprintf(
				"host=%s port=%s user=%s dbname=postgres sslmode=disable", 
				host, port, currentUser)
			testDB, testErr := sql.Open("postgres", testConnStr)
			if testErr == nil {
				pingErr := testDB.Ping()
				testDB.Close()
				if pingErr == nil {
					log.Printf("Successfully connected with system username: %s", currentUser)
					user = currentUser
				} else {
					log.Printf("Could not connect with system username: %v", pingErr)
				}
			}
		}
		
		// If system username didn't work, try with other common options
		if user == "" {
			// Common usernames for PostgreSQL
			testUsers := []string{"danielcarneiro", "postgres", "root", "admin"}
			
			for _, testUser := range testUsers {
				log.Printf("Trying connection with username: %s", testUser)
				testConnStr := fmt.Sprintf(
					"host=%s port=%s user=%s dbname=postgres sslmode=disable", 
					host, port, testUser)
				testDB, testErr := sql.Open("postgres", testConnStr)
				if testErr == nil {
					pingErr := testDB.Ping()
					testDB.Close()
					if pingErr == nil {
						log.Printf("Successfully connected with username: %s", testUser)
						user = testUser
						break
					}
				}
			}
		}
		
		// If we still don't have a working user, default to system username as last resort
		if user == "" {
			user = os.Getenv("USER") // Use system username as last resort
			log.Printf("No working PostgreSQL user found, defaulting to: %s", user)
		}
	}

	password := os.Getenv("POSTGRES_PASSWORD")
	if password == "" {
		password = os.Getenv("DB_PASSWORD") // Check alternative env var
	}

	dbname := os.Getenv("POSTGRES_DB")
	if dbname == "" {
		dbname = os.Getenv("DB_NAME") // Check alternative env var
		if dbname == "" {
			dbname = "groovegarden"
		}
	}

	// Use DATABASE_URL if provided, otherwise build from components
	connStr := os.Getenv("DATABASE_URL")
	if connStr == "" {
		// First try without password (common for local development on macOS)
		if password == "" {
			log.Printf("Building connection string with user=%s, host=%s, port=%s, dbname=%s (no password)", 
				user, host, port, dbname)
			connStr = fmt.Sprintf("host=%s port=%s user=%s dbname=%s sslmode=disable",
				host, port, user, dbname)
		} else {
			log.Printf("Building connection string with user=%s, host=%s, port=%s, dbname=%s (with password)", 
				user, host, port, dbname)
			connStr = fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
				host, port, user, password, dbname)
		}
		log.Printf("DATABASE_URL not set, using connection string: host=%s port=%s user=%s dbname=%s",
			host, port, user, dbname)
	}

	// Connect to the database
	log.Printf("Connecting to PostgreSQL database...")
	var err error
	DB, err = sql.Open("postgres", connStr)
	if err != nil {
		return fmt.Errorf("error opening database: %w", err)
	}

	// Check the connection with more detailed error handling
	err = DB.Ping()
	if err != nil {
		// Try to create the database if it doesn't exist
		if strings.Contains(err.Error(), "does not exist") && dbname != "postgres" {
			log.Printf("Database %s doesn't exist, attempting to create it", dbname)
			
			// Connect to default postgres database to create our database
			defaultConnStr := fmt.Sprintf("host=%s port=%s user=%s sslmode=disable dbname=postgres", 
				host, port, user)
			if password != "" {
				defaultConnStr += fmt.Sprintf(" password=%s", password)
			}
			
			defaultDB, defaultErr := sql.Open("postgres", defaultConnStr)
			if defaultErr == nil {
				defer defaultDB.Close()
				
				// Create database
				_, createErr := defaultDB.Exec(fmt.Sprintf("CREATE DATABASE %s", dbname))
				if createErr == nil {
					log.Printf("Created database %s successfully", dbname)
					// Try connecting again
					err = DB.Ping()
				} else {
					log.Printf("Failed to create database: %v", createErr)
				}
			}
		}
		
		if err != nil {
			// Still error after recovery attempts
			log.Printf("Connection error details: %v", err)
			return fmt.Errorf("error connecting to database: %w\n\nPlease check:\n1. PostgreSQL is running\n2. User '%s' exists\n3. Database '%s' exists\n4. Connection credentials are correct", 
				err, user, dbname)
		}
	}

	// Set connection pool parameters
	DB.SetMaxOpenConns(25)
	DB.SetMaxIdleConns(5)
	DB.SetConnMaxLifetime(5 * time.Minute)

	log.Println("Database connection established successfully")

	// Ensure tables exist - consolidated from both implementations
	err = InitializeDatabase()
	if err != nil {
		return fmt.Errorf("error ensuring tables exist: %w", err)
	}

	return nil
}

// InitDB is an alias for Connect for backwards compatibility
func InitDB() error {
	return Connect()
}

// InitializeDatabase creates necessary tables if they don't exist
// Consolidated from both implementations (database.go and init.go)
func InitializeDatabase() error {
	log.Println("Initializing database schema...")
	
	// Create users table if it doesn't exist (merged implementation)
	_, err := DB.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id SERIAL PRIMARY KEY,
			name TEXT NOT NULL,
			email TEXT UNIQUE NOT NULL,
			account_type TEXT NOT NULL DEFAULT 'listener',
			profile_picture TEXT,
			bio TEXT,
			links JSONB,
			music_preferences JSONB,
			location TEXT,
			date_of_birth TEXT,
			created_at TIMESTAMP DEFAULT NOW(),
			last_seen TIMESTAMP DEFAULT NOW()
		)
	`)

	if err != nil {
		return fmt.Errorf("error creating users table: %w", err)
	}

	// Create songs table if it doesn't exist (merged implementation)
	_, err = DB.Exec(`
		CREATE TABLE IF NOT EXISTS songs (
			id SERIAL PRIMARY KEY,
			title TEXT NOT NULL,
			artist TEXT,
			artist_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
			duration INTEGER DEFAULT 0,
			storage_path TEXT,
			votes INTEGER DEFAULT 0,
			upload_date TIMESTAMP DEFAULT NOW()
		)
	`)

	if err != nil {
		return fmt.Errorf("error creating songs table: %w", err)
	}

	// Insert default users if not exist
	_, err = DB.Exec(`
		INSERT INTO users (id, name, email, account_type)
		VALUES 
			(1, 'Admin User', 'admin@groovegarden.com', 'admin'),
			(2, 'Artist User', 'artist@groovegarden.com', 'artist'),
			(3, 'Listener User', 'listener@groovegarden.com', 'listener')
		ON CONFLICT (id) DO NOTHING
	`)

	if err != nil {
		return fmt.Errorf("error inserting default users: %w", err)
	}

	log.Println("Database schema initialized successfully")
	return nil
}

// ensureTablesExist is kept as a private alias for InitializeDatabase
// for backward compatibility with existing code
func ensureTablesExist() error {
	return InitializeDatabase()
}
