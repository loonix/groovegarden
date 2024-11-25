package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/joho/godotenv"

	"groovegarden/controllers"
	"groovegarden/database"
	"groovegarden/oauth"
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

	// Register routes
	routes.RegisterRoutes(router)

	// WebSocket routes
	go websocket.HandleMessages()
	router.HandleFunc("/ws", websocket.HandleConnections)

	// Load environment variables
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	// Get OAuth credentials from environment variables
	clientID := os.Getenv("GOOGLE_CLIENT_ID")
	clientSecret := os.Getenv("GOOGLE_CLIENT_SECRET")
	redirectURL := os.Getenv("REDIRECT_URL")

	// Initialize Google OAuth
	oauth.InitGoogleOAuth(clientID, clientSecret, redirectURL)

	// OAuth routes
	router.Get("/oauth/login", controllers.GoogleLogin)
	router.Get("/oauth/callback", controllers.GoogleCallback)

	// Start the server
	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "8081" // Default port if not specified in .env
	}
	fmt.Printf("Starting server on port %s...\n", port)
	log.Fatal(http.ListenAndServe(":"+port, router))
}

// CORS Middleware
func corsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Access-Control-Allow-Origin", "http://localhost:60387")
        w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

        if r.Method == "OPTIONS" {
            w.WriteHeader(http.StatusOK)
            return
        }

        next.ServeHTTP(w, r)
    })
}
