package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
)

// DB is the global database connection
var DB *sql.DB

// Connect establishes a connection to the database
func Connect() error {
	host := os.Getenv("POSTGRES_HOST")
	if host == "" {
		host = "localhost"
	}

	port := os.Getenv("POSTGRES_PORT")
	if port == "" {
		port = "5432"
	}

	user := os.Getenv("POSTGRES_USER")
	if user == "" {
		user = "grooveuser"
	}

	password := os.Getenv("POSTGRES_PASSWORD")
	if password == "" {
		password = "groovepass"
	}

	dbname := os.Getenv("POSTGRES_DB")
	if dbname == "" {
		dbname = "groovegarden"
	}

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	var err error
	DB, err = sql.Open("postgres", connStr)
	if err != nil {
		return fmt.Errorf("failed to open database connection: %w", err)
	}

	err = DB.Ping()
	if err != nil {
		return fmt.Errorf("failed to ping database: %w. Please check if PostgreSQL is running and credentials are correct (see README.md for setup instructions)", err)
	}

	log.Println("Database connected!")
	
	// Initialize database schema
	if err := InitializeDatabase(); err != nil {
		return err
	}
	
	return nil
}

// GetDB returns the database connection
func GetDB() (*sql.DB, error) {
	if DB == nil {
		if err := Connect(); err != nil {
			return nil, err
		}
	}
	return DB, nil
}