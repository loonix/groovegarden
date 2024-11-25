package models

type Song struct {
	ID       int    `json:"id"`
	Title    string `json:"title"`
	FilePath string `json:"file_path"` 
	Votes    int    `json:"votes"`
}
