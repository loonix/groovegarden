package database

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
)

var DB *sql.DB

func InitDB() {
	connStr := "host=localhost port=5432 user=grooveuser password=groovepass dbname=groovegarden sslmode=disable"
	var err error
	DB, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	err = DB.Ping()
	if err != nil {
		log.Fatal("Failed to ping database:", err)
	}

	fmt.Println("Database connected!")

	// Create the 'songs' table if it does not exist
	createTableQuery := `
	CREATE TABLE IF NOT EXISTS songs (
		id SERIAL PRIMARY KEY,
		title VARCHAR(255) NOT NULL,
		url VARCHAR(255) NOT NULL,
		votes INTEGER DEFAULT 0
	);
	`
	_, err = DB.Exec(createTableQuery)
	if err != nil {
		log.Fatal("Failed to create table:", err)
	}

	fmt.Println("Table 'songs' ensured to exist")
}