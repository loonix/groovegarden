package oauth

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"golang.org/x/oauth2"

	"groovegarden/controllers"
	"groovegarden/utils"
)

// GoogleLogin initiates the OAuth flow
func GoogleLogin(w http.ResponseWriter, r *http.Request) {
	url := GoogleOAuthConfig.AuthCodeURL("state-token", oauth2.AccessTypeOffline)
	http.Redirect(w, r, url, http.StatusTemporaryRedirect)
}

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
	userID, err := controllers.UpsertUserFromOAuth(user)
	if err != nil {
		http.Error(w, "Failed to upsert user: "+err.Error(), http.StatusInternalServerError)
		return
	}

// After upserting the user, retrieve their role
userRole := user["account_type"].(string) // Assuming the role is returned in user data

// Generate the JWT
jwtToken, err := utils.GenerateJWT(userID, userRole)
if err != nil {
	http.Error(w, "Failed to generate JWT: "+err.Error(), http.StatusInternalServerError)
	return
}


	// Send the JWT to the client
	http.SetCookie(w, &http.Cookie{
		Name:     "token",
		Value:    jwtToken,
		Expires:  time.Now().Add(24 * time.Hour),
		HttpOnly: true, // Prevents JavaScript access
	})
	fmt.Fprintf(w, "Welcome, %s!", userInfo.Name)
}
