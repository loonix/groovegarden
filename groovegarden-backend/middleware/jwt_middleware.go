package middleware

import (
	"context"
	"net/http"
	"strings"

	"groovegarden/utils"
)

// RoleCheckMiddleware validates the user's role from the JWT
func RoleCheckMiddleware(requiredRole string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Extract the token from the Authorization header
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				http.Error(w, "Authorization header missing", http.StatusUnauthorized)
				return
			}

			tokenString := strings.TrimPrefix(authHeader, "Bearer ")
			if tokenString == authHeader {
				http.Error(w, "Invalid token format", http.StatusUnauthorized)
				return
			}

			// Validate the JWT and extract claims
			claims, err := utils.ValidateJWTAndGetClaims(tokenString)
			if err != nil {
				http.Error(w, "Invalid or expired token: "+err.Error(), http.StatusUnauthorized)
				return
			}

			// Check the user's role from the claims
			userRole, ok := claims["role"].(string)
			if !ok || userRole != requiredRole {
				http.Error(w, "Access denied: insufficient permissions", http.StatusForbidden)
				return
			}

			// Proceed to the next handler
			next.ServeHTTP(w, r)
		})
	}
}

func JWTAuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Extract the token from the Authorization header
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "Authorization header missing", http.StatusUnauthorized)
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			http.Error(w, "Invalid token format", http.StatusUnauthorized)
			return
		}

		// Validate the JWT and extract claims
		claims, err := utils.ValidateJWTAndGetClaims(tokenString)
		if err != nil {
			http.Error(w, "Invalid or expired token: "+err.Error(), http.StatusUnauthorized)
			return
		}

		// Extract the user_id from the claims
		userID, ok := claims["user_id"].(float64)
		if !ok {
			http.Error(w, "Invalid token claims: missing user_id", http.StatusUnauthorized)
			return
		}

		// Add user ID to request context
		ctx := r.Context()
		ctx = context.WithValue(ctx, "user_id", int(userID)) // Convert float64 to int
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}