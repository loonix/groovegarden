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
	// Load environment variables
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	// Initialize database connection
	if err := database.Connect(); err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	fmt.Println("Database initialized")

	// Set up the router
	router := chi.NewRouter()
	router.Use(corsMiddleware)

	// Print out important configuration values for debugging
	fmt.Println("OAuth Redirect URL:", os.Getenv("REDIRECT_URL"))
	fmt.Println("Frontend Origin is expected to be:", "http://localhost:54321")

	// Register routes
	routes.RegisterRoutes(router)

	// WebSocket routes
	go websocket.HandleMessages()
	router.HandleFunc("/ws", websocket.HandleConnections)

	// Streaming routes
	router.Get("/stream/start", controllers.StartStream)
	router.Get("/stream/stop", controllers.StopStream)

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
		// Get the origin from the request or use a default
		origin := r.Header.Get("Origin")
		if origin == "" {
			origin = "http://localhost:54321" // Default frontend origin
		}

		w.Header().Set("Access-Control-Allow-Origin", origin)
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		w.Header().Set("Access-Control-Allow-Credentials", "true")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}
