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
	connStr := os.Getenv("DATABASE_URL")
	if connStr == "" {
		// Fallback to default connection string using credentials from README
		connStr = "postgres://grooveuser:groovepass@localhost:5432/groovegarden?sslmode=disable"
	}

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