package routes

import (
	"net/http"

	"github.com/go-chi/chi/v5"

	"groovegarden/controllers"
	"groovegarden/middleware"
)

func RegisterRoutes(router *chi.Mux) {
	router.Get("/songs", controllers.GetSongs)

	router.Post("/vote/{id}", func(w http.ResponseWriter, r *http.Request) {
		middleware.JWTAuthMiddleware(http.HandlerFunc(controllers.VoteForSong)).ServeHTTP(w, r)
	})

	router.Post("/add", func(w http.ResponseWriter, r *http.Request) {
		middleware.JWTAuthMiddleware(http.HandlerFunc(controllers.AddSong)).ServeHTTP(w, r)
	})

	// User routes
	router.Post("/users/upsert", controllers.UpsertUser)
	router.Get("/users", controllers.GetUserByEmail)
}
