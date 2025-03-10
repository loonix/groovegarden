package routes

import (
	"net/http"

	"github.com/go-chi/chi/v5"

	"groovegarden/controllers"
	"groovegarden/middleware"
	"groovegarden/utils"
)

func RegisterRoutes(router *chi.Mux) {
	// Google OAuth routes
	router.Route("/google", func(r chi.Router) {
		r.Get("/login", controllers.GoogleLogin)
		r.Get("/callback", controllers.GoogleCallback)
	})

	// Song-related routes
	router.Route("/songs", func(r chi.Router) {
		r.Get("/", controllers.GetSongs) // Public route to fetch songs

		// Routes requiring authentication
		r.Group(func(auth chi.Router) {
			auth.Use(middleware.JWTAuthMiddleware)

			// Voting for songs
			auth.Post("/vote/{id}", controllers.VoteForSong)

			// Routes restricted to artists
			auth.Group(func(artist chi.Router) {
				artist.Use(middleware.RoleCheckMiddleware("artist"))
				artist.Post("/upload", controllers.UploadSong)
				artist.Post("/add", controllers.AddSong)
			})
		})
	})

	// Song streaming routes
	router.Route("/stream", func(r chi.Router) {
		r.Get("/{id}", controllers.StreamSong)       // Stream a specific song (public access)
		r.Post("/start", controllers.StartStream)    // Start the global stream (requires admin privileges later)
		r.Post("/stop", controllers.StopStream)      // Stop the global stream (requires admin privileges later)
	})

	// User-related routes
	router.Route("/users", func(r chi.Router) {
		r.Post("/upsert", controllers.UpsertUser)
		r.Get("/", controllers.GetUserByEmail)
		r.Get("/{id}", controllers.GetUserByID)
	})

	// Add token refresh route
	router.Route("/auth", func(r chi.Router) {
		r.Post("/refresh", controllers.RefreshToken)
	})

	// Utility routes
	router.Get("/generate-token", func(w http.ResponseWriter, r *http.Request) {
		token, err := utils.GenerateJWT(1, "artist") // Example: Generate a token for User ID 1
		if err != nil {
			http.Error(w, "Failed to generate token: "+err.Error(), http.StatusInternalServerError)
			return
		}

		w.Write([]byte(token))
	})
}
