package routes

import (
	"net/http"

	"github.com/go-chi/chi/v5"

	"groovegarden/controllers"
	"groovegarden/middleware"
	"groovegarden/utils"
)

func RegisterRoutes(router *chi.Mux) {
	router.Get("/google/login", controllers.GoogleLogin)
	router.Get("/google/callback", controllers.GoogleCallback)

	router.Get("/songs", controllers.GetSongs)

	router.Post("/upload", func(w http.ResponseWriter, r *http.Request) {
		middleware.RoleCheckMiddleware("artist")(http.HandlerFunc(controllers.UploadSong)).ServeHTTP(w, r)
	})
	router.Get("/stream/{id}", controllers.StreamSong)


	// Protected route with JWTAuthMiddleware
	router.Post("/vote/{id}", func(w http.ResponseWriter, r *http.Request) {
		middleware.JWTAuthMiddleware(http.HandlerFunc(controllers.VoteForSong)).ServeHTTP(w, r)
	})

	// Route restricted to artists using RoleCheckMiddleware
	router.Post("/add", func(w http.ResponseWriter, r *http.Request) {
		middleware.RoleCheckMiddleware("artist")(http.HandlerFunc(controllers.AddSong)).ServeHTTP(w, r)
	})
	// User routes
	router.Post("/users/upsert", controllers.UpsertUser)
	router.Get("/users", controllers.GetUserByEmail)

	router.Get("/generate-token", func(w http.ResponseWriter, r *http.Request) {
		// Example: Generating a token for an artist
		token, err := utils.GenerateJWT(1, "artist") // User ID: 1, Role: "artist"
		if err != nil {
			http.Error(w, "Failed to generate token: "+err.Error(), http.StatusInternalServerError)
			return
		}
	
		w.Write([]byte(token))
	})
	
}
