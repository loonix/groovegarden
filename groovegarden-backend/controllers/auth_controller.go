package controllers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"

	"groovegarden/utils"
)

// Initialize OAuth config in a function to ensure it uses the latest env vars
func getGoogleOAuthConfig() *oauth2.Config {
	return &oauth2.Config{
		ClientID:     os.Getenv("GOOGLE_CLIENT_ID"),
		ClientSecret: os.Getenv("GOOGLE_CLIENT_SECRET"),
		RedirectURL:  os.Getenv("REDIRECT_URL"),
		Scopes:       []string{"https://www.googleapis.com/auth/userinfo.email", "https://www.googleapis.com/auth/userinfo.profile"},
		Endpoint:     google.Endpoint,
	}
}

// GoogleLogin redirects users to the Google OAuth consent page
func GoogleLogin(w http.ResponseWriter, r *http.Request) {
	// Get the origin of the request (to redirect back to later)
	origin := r.Header.Get("Referer")
	if origin == "" {
		origin = r.Header.Get("Origin")
	}
	if origin == "" {
		// Default to port 54321 if origin headers aren't available
		origin = "http://localhost:54321"
	}

	// Clean up the origin to just get the base URL
	parsedOrigin, err := url.Parse(origin)
	if err == nil {
		origin = parsedOrigin.Scheme + "://" + parsedOrigin.Host
	}

	// Use state parameter to store the origin (encoded)
	state := url.QueryEscape(origin)
	
	// Get the latest OAuth config
	googleOauthConfig := getGoogleOAuthConfig()
	url := googleOauthConfig.AuthCodeURL(state)
	
	fmt.Println("Redirecting to Google with state:", state)
	fmt.Println("Origin determined as:", origin)
	
	http.Redirect(w, r, url, http.StatusTemporaryRedirect)
}

// GoogleCallback handles the callback from Google OAuth
func GoogleCallback(w http.ResponseWriter, r *http.Request) {
	code := r.URL.Query().Get("code")
	if code == "" {
		http.Error(w, "Authorization code missing", http.StatusBadRequest)
		return
	}

	// Get the origin from state parameter
	state := r.URL.Query().Get("state")
	fmt.Println("Callback received with state:", state)
	
	origin, err := url.QueryUnescape(state)
	if err != nil || origin == "" {
		// Fallback to default if there's an issue with the state
		origin = "http://localhost:54321"
		fmt.Println("Using default origin due to state issue:", err)
	}
	
	fmt.Println("Origin for redirect:", origin)

	// Get the latest OAuth config
	googleOauthConfig := getGoogleOAuthConfig()
	
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

	// Redirect back to the frontend with the token, using the original origin
	redirectURL := fmt.Sprintf("%s?token=%s", origin, jwtToken)
	fmt.Println("Redirecting to:", redirectURL)

	// Set Cache-Control headers to prevent caching
	w.Header().Set("Cache-Control", "no-store, no-cache, must-revalidate, post-check=0, pre-check=0")
	w.Header().Set("Pragma", "no-cache")
	w.Header().Set("Expires", "0")

	http.Redirect(w, r, redirectURL, http.StatusSeeOther)
}

// fetchGoogleUserInfo retrieves user info from Google using the provided token
func fetchGoogleUserInfo(token *oauth2.Token) (*struct {
	Email string `json:"email"`
	Name  string `json:"name"`
}, error) {
	client := getGoogleOAuthConfig().Client(context.Background(), token)
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
