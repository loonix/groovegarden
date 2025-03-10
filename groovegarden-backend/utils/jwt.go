package utils

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// GenerateJWT generates a JWT token for a user ID and role
func GenerateJWT(userID int, role string) (string, error) {
	// Create token with claims
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": userID,
		"role":    role,
		"exp":     time.Now().Add(time.Hour * 72).Unix(), // Token expires in 72 hours
	})

	// Sign the token with a secret key
	secretKey := os.Getenv("JWT_SECRET")
	if secretKey == "" {
		// Fallback to a default for development - log a warning
		log.Println("WARNING: JWT_SECRET not set! Using development fallback. Not secure for production.")
		secretKey = "groovegarden_default_secret_key_for_development_only"
	}

	tokenString, err := token.SignedString([]byte(secretKey))
	if err != nil {
		return "", fmt.Errorf("failed to sign token: %w", err)
	}

	return tokenString, nil
}

// ValidateJWTAndGetClaims validates JWT and returns claims
func ValidateJWTAndGetClaims(tokenString string) (jwt.MapClaims, error) {
	// Check if JWT_SECRET is set
	secretKey := os.Getenv("JWT_SECRET")
	if secretKey == "" {
		// Fallback to a default for development - log a warning
		log.Println("WARNING: JWT_SECRET not set during validation! Using development fallback.")
		secretKey = "groovegarden_default_secret_key_for_development_only"
	}

	// Parse the token
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		// Validate signing method
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(secretKey), nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}

	// Extract claims
	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		return claims, nil
	}

	return nil, fmt.Errorf("invalid token")
}

// ExtractClaimsWithoutValidation extracts claims without validating the token
func ExtractClaimsWithoutValidation(tokenString string) (jwt.MapClaims, error) {
	// Split the token
	parts := strings.Split(tokenString, ".")
	if len(parts) != 3 {
		return nil, fmt.Errorf("token contains an invalid number of segments")
	}

	// Decode the payload (claims)
	var payloadBytes []byte
	var err error
	
	// Handle padding
	payload := parts[1]
	if l := len(payload) % 4; l > 0 {
		payload += strings.Repeat("=", 4-l)
	}
	
	payloadBytes, err = base64.URLEncoding.DecodeString(payload)
	if err != nil {
		// Try with RawURLEncoding
		payloadBytes, err = base64.RawURLEncoding.DecodeString(parts[1])
		if err != nil {
			return nil, fmt.Errorf("error decoding token claims: %v", err)
		}
	}

	// Parse the claims
	var claims jwt.MapClaims
	err = json.Unmarshal(payloadBytes, &claims)
	if err != nil {
		return nil, fmt.Errorf("error parsing token claims: %v", err)
	}

	return claims, nil
}

