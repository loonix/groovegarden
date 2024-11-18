package main

import (
	"fmt"
	"net/http"

	"github.com/go-chi/chi/v5"

	"groovegarden/database"
	"groovegarden/routes"
)

func main() {
	// Initialize the database
	database.InitDB()
	fmt.Println("Database initialized")

	// Set up the router
	router := chi.NewRouter()
	router.Use(corsMiddleware)
	fmt.Println("Router initialized with CORS")

	// Register routes
	routes.RegisterRoutes(router)
	fmt.Println("Routes registered")

	// WebSocket route
	// go handleMessages()
	// fmt.Println("WebSocket route initialized")
	// router.HandleFunc("/ws", handleConnections)

	// Start the server and listen on port 8080
	fmt.Println("Starting server on port 8080...")
	if err := http.ListenAndServe(":8080", router); err != nil {
		fmt.Printf("Error starting server: %v\n", err)
	}
}

// CORS Middleware
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		next.ServeHTTP(w, r)
	})
}
