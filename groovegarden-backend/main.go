package main

import (
	"fmt"
	"net/http"

	"github.com/go-chi/chi/v5"

	"groovegarden/database"
	"groovegarden/routes"
	"groovegarden/websocket"
)

func main() {
	// Initialize the database
	database.InitDB()
	fmt.Println("Database initialized")

	// Set up the router
	router := chi.NewRouter()
	router.Use(corsMiddleware)
	fmt.Println("Router initialized with CORS")

	// Register existing routes
	routes.RegisterRoutes(router)

	// Set up WebSocket routes
	go websocket.HandleMessages()
	router.HandleFunc("/ws", websocket.HandleConnections)
	fmt.Println("WebSocket route initialized")

	// Start the server
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
