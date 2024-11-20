package oauth

import (
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

// GoogleOAuthConfig holds the configuration for Google OAuth2
var GoogleOAuthConfig *oauth2.Config

// InitGoogleOAuth initializes the Google OAuth2 configuration
func InitGoogleOAuth(clientID, clientSecret, redirectURL string) {
	GoogleOAuthConfig = &oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		RedirectURL:  redirectURL,
		Scopes:       []string{"https://www.googleapis.com/auth/userinfo.email", "https://www.googleapis.com/auth/userinfo.profile"},
		Endpoint:     google.Endpoint,
	}
}
