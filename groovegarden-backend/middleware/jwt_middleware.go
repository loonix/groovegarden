package middleware

import (
	"context"
	"log"
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
        authHeader := r.Header.Get("Authorization")
        log.Printf("Authorization Header: %s", authHeader)
        if authHeader == "" {
            http.Error(w, "Authorization header missing", http.StatusUnauthorized)
            return
        }

        tokenString := strings.TrimPrefix(authHeader, "Bearer ")
        log.Printf("Extracted Token: %s", tokenString)
        if tokenString == authHeader {
            http.Error(w, "Invalid token format", http.StatusUnauthorized)
            return
        }

        claims, err := utils.ValidateJWTAndGetClaims(tokenString)
        if err != nil {
            log.Printf("Token validation error: %v", err)
            http.Error(w, "Invalid or expired token: "+err.Error(), http.StatusUnauthorized)
            return
        }

        userID, ok := claims["user_id"].(float64) // JWT numbers are float64
        if !ok {
            http.Error(w, "Invalid user_id in token", http.StatusUnauthorized)
            return
        }

        role, ok := claims["role"].(string)
        if !ok {
            http.Error(w, "Invalid role in token", http.StatusUnauthorized)
            return
        }

        // Add to context
        ctx := context.WithValue(r.Context(), "user_id", int(userID))
        ctx = context.WithValue(ctx, "role", role)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}

