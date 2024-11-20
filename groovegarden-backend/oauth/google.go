package oauth

import (
	"encoding/json"
	"fmt"
	"net/http"

	"golang.org/x/oauth2"

	"groovegarden/controllers"
)

// GoogleLogin initiates the OAuth flow
func GoogleLogin(w http.ResponseWriter, r *http.Request) {
	url := GoogleOAuthConfig.AuthCodeURL("state-token", oauth2.AccessTypeOffline)
	http.Redirect(w, r, url, http.StatusTemporaryRedirect)
}

// GoogleCallback handles the OAuth callback
func GoogleCallback(w http.ResponseWriter, r *http.Request) {
	code := r.URL.Query().Get("code")
	if code == "" {
		http.Error(w, "Code not found", http.StatusBadRequest)
		return
	}

	// Exchange the authorization code for an access token
	token, err := GoogleOAuthConfig.Exchange(r.Context(), code)
	if err != nil {
		http.Error(w, "Failed to exchange token: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Retrieve user info from Google
	client := GoogleOAuthConfig.Client(r.Context(), token)
	resp, err := client.Get("https://www.googleapis.com/oauth2/v2/userinfo")
	if err != nil {
		http.Error(w, "Failed to get user info: "+err.Error(), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	var userInfo struct {
		ID            string `json:"id"`
		Email         string `json:"email"`
		Name          string `json:"name"`
		Picture       string `json:"picture"`
		VerifiedEmail bool   `json:"verified_email"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&userInfo); err != nil {
		http.Error(w, "Failed to decode user info: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Upsert the user into the database
	user := map[string]interface{}{
		"name":            userInfo.Name,
		"email":           userInfo.Email,
		"account_type":    "listener", // Default type
		"profile_picture": userInfo.Picture,
	}
	err = controllers.UpsertUserFromOAuth(user)
	if err != nil {
		http.Error(w, "Failed to upsert user: "+err.Error(), http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, "Welcome, %s!", userInfo.Name)
}
