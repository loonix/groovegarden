package controllers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"

	"groovegarden/utils"
)

var googleOauthConfig = &oauth2.Config{
	ClientID:     os.Getenv("GOOGLE_CLIENT_ID"),
	ClientSecret: os.Getenv("GOOGLE_CLIENT_SECRET"),
	RedirectURL:  "http://localhost:8081/google/callback", // Ensure this matches
	Scopes:       []string{"https://www.googleapis.com/auth/userinfo.email", "https://www.googleapis.com/auth/userinfo.profile"},
	Endpoint:     google.Endpoint,
}

// GoogleLogin redirects users to the Google OAuth consent page
func GoogleLogin(w http.ResponseWriter, r *http.Request) {
	url := googleOauthConfig.AuthCodeURL("state-token")
	http.Redirect(w, r, url, http.StatusTemporaryRedirect)
}

// GoogleCallback handles the callback from Google OAuth
func GoogleCallback(w http.ResponseWriter, r *http.Request) {
	code := r.URL.Query().Get("code")
	if code == "" {
		http.Error(w, "Authorization code missing", http.StatusBadRequest)
		return
	}

	// Exchange the authorization code for an access token
	token, err := googleOauthConfig.Exchange(context.Background(), code)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to exchange token: %v", err), http.StatusInternalServerError)
		return
	}

	// Retrieve user info from Google
	userInfo, err := fetchGoogleUserInfo(token)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to get user info: %v", err), http.StatusInternalServerError)
		return
	}

	// Create or update the user in the database
	user := map[string]interface{}{
		"email":           userInfo.Email,
		"name":            userInfo.Name,
		"account_type":    "listener", // Default role, will be updated in UpsertUserFromOAuth
		"profile_picture": "",         // Add profile picture if available
	}

	userID, err := UpsertUserFromOAuth(user)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to upsert user: %v", err), http.StatusInternalServerError)
		return
	}

	// Use the role fetched or updated in the database
	role := user["account_type"].(string)

	// Generate a JWT for the user
	jwtToken, err := utils.GenerateJWT(userID, role)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to generate token: %v", err), http.StatusInternalServerError)
		return
	}

	// Redirect back to the frontend with the token
	redirectURL := fmt.Sprintf("http://localhost:60387?token=%s", jwtToken)
	http.Redirect(w, r, redirectURL, http.StatusSeeOther)
}



// fetchGoogleUserInfo retrieves user info from Google using the provided token
func fetchGoogleUserInfo(token *oauth2.Token) (*struct {
	Email string `json:"email"`
	Name  string `json:"name"`
}, error) {
	client := googleOauthConfig.Client(context.Background(), token)
	resp, err := client.Get("https://www.googleapis.com/oauth2/v2/userinfo")
	if err != nil {
		return nil, fmt.Errorf("failed to fetch user info: %w", err)
	}
	defer resp.Body.Close()

	var userInfo struct {
		Email string `json:"email"`
		Name  string `json:"name"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&userInfo); err != nil {
		return nil, fmt.Errorf("failed to decode user info: %w", err)
	}

	return &userInfo, nil
}
