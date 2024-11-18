package routes

import (
	"github.com/go-chi/chi/v5"

	"groovegarden/controllers"
)

// Update RegisterRoutes to accept a *chi.Mux parameter
func RegisterRoutes(router *chi.Mux) {
	router.Get("/songs", controllers.GetSongs)
	router.Post("/vote/{id}", controllers.VoteForSong)
	router.Post("/add", controllers.AddSong)
}
