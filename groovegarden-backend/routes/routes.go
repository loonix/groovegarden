package routes

import (
	"github.com/go-chi/chi/v5"

	"groovegarden/controllers"
)

func RegisterRoutes(router *chi.Mux) {
	router.Get("/songs", controllers.GetSongs)
	router.Post("/vote/{id}", controllers.VoteForSong)
	router.Post("/add", controllers.AddSong)

	// User routes
	router.Post("/users/upsert", controllers.UpsertUser)
	router.Get("/users", controllers.GetUserByEmail)
}
