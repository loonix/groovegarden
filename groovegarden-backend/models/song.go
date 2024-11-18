package models

type Song struct {
	ID    int    `json:"id"`
	Title string `json:"title"`
	URL   string `json:"url"`
	Votes int    `json:"votes"`
}
