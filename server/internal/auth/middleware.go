package auth

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"net/http"
	"strings"
	"time"
)

type contextKey string

const userIDKey contextKey = "user_id"

type tokenPayload struct {
	UserID    string `json:"uid"`
	ExpiresAt int64  `json:"exp"`
}

func GenerateToken(secret string, userID string) (string, error) {
	payload := tokenPayload{
		UserID:    userID,
		ExpiresAt: time.Now().Add(30 * 24 * time.Hour).Unix(),
	}
	data, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}
	encoded := base64.RawURLEncoding.EncodeToString(data)
	sig := sign(secret, encoded)
	return encoded + "." + sig, nil
}

// Middleware validates the old custom HMAC token format.
func Middleware(secret string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token := extractToken(r)
			if token == "" {
				http.Error(w, `{"error":"unauthorized"}`, http.StatusUnauthorized)
				return
			}

			parts := strings.SplitN(token, ".", 2)
			if len(parts) != 2 {
				http.Error(w, `{"error":"invalid token"}`, http.StatusUnauthorized)
				return
			}

			if sign(secret, parts[0]) != parts[1] {
				http.Error(w, `{"error":"invalid token"}`, http.StatusUnauthorized)
				return
			}

			data, err := base64.RawURLEncoding.DecodeString(parts[0])
			if err != nil {
				http.Error(w, `{"error":"invalid token"}`, http.StatusUnauthorized)
				return
			}

			var payload tokenPayload
			if err := json.Unmarshal(data, &payload); err != nil {
				http.Error(w, `{"error":"invalid token"}`, http.StatusUnauthorized)
				return
			}

			if time.Now().Unix() > payload.ExpiresAt {
				http.Error(w, `{"error":"token expired"}`, http.StatusUnauthorized)
				return
			}

			ctx := context.WithValue(r.Context(), userIDKey, payload.UserID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// CombinedMiddleware tries Casdoor JWT first, then falls back to the old HMAC token.
// This allows both the mobile app (Casdoor) and web frontend (old auth) to work.
func CombinedMiddleware(secret string, casdoor *CasdoorAuth, userLookup func(provider, subject string) (string, error)) func(http.Handler) http.Handler {
	oldMiddleware := Middleware(secret)

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token := extractToken(r)
			if token == "" {
				http.Error(w, `{"error":"unauthorized"}`, http.StatusUnauthorized)
				return
			}

			// Try Casdoor JWT first (JWTs have 3 dot-separated parts)
			if casdoor != nil && strings.Count(token, ".") == 2 {
				claims, err := casdoor.ValidateToken(token)
				if err == nil {
					// Look up or create the user by Casdoor subject
					subject := claims.Subject
					if subject == "" {
						subject = claims.Name
					}
					userID, err := userLookup("casdoor", subject)
					if err == nil && userID != "" {
						ctx := context.WithValue(r.Context(), userIDKey, userID)
						next.ServeHTTP(w, r.WithContext(ctx))
						return
					}
				}
				// Casdoor validation failed — fall through to old auth
			}

			// Fall back to old HMAC token auth
			oldMiddleware(next).ServeHTTP(w, r)
		})
	}
}

func UserID(ctx context.Context) string {
	id, _ := ctx.Value(userIDKey).(string)
	return id
}

func extractToken(r *http.Request) string {
	if h := r.Header.Get("Authorization"); strings.HasPrefix(h, "Bearer ") {
		return h[7:]
	}
	return ""
}

func sign(secret, data string) string {
	mac := hmac.New(sha256.New, []byte(secret))
	mac.Write([]byte(data))
	return base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
}
