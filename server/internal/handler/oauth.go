package handler

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"

	"cat-calories-server/internal/usecase"

	"golang.org/x/oauth2"
)

type OAuthHandler struct {
	Auth     *usecase.AuthUseCase
	Google   *oauth2.Config
	Facebook *oauth2.Config
}

// GET /auth/google/login
func (h *OAuthHandler) GoogleLogin(w http.ResponseWriter, r *http.Request) {
	state := randomState()
	http.SetCookie(w, &http.Cookie{Name: "oauth_state", Value: state, Path: "/", HttpOnly: true, SameSite: http.SameSiteLaxMode})
	http.Redirect(w, r, h.Google.AuthCodeURL(state), http.StatusTemporaryRedirect)
}

// GET /auth/google/callback
func (h *OAuthHandler) GoogleCallback(w http.ResponseWriter, r *http.Request) {
	if err := validateState(r); err != nil {
		jsonError(w, "invalid state", http.StatusBadRequest)
		return
	}

	token, err := h.Google.Exchange(r.Context(), r.URL.Query().Get("code"))
	if err != nil {
		jsonError(w, "oauth exchange failed", http.StatusBadRequest)
		return
	}

	client := h.Google.Client(r.Context(), token)
	info, err := fetchGoogleUserInfo(client)
	if err != nil {
		jsonError(w, "failed to get user info", http.StatusInternalServerError)
		return
	}

	tok, err := h.Auth.LoginOAuth("google", info.Sub, info.Email, info.Name)
	if err != nil {
		jsonError(w, "auth failed", http.StatusInternalServerError)
		return
	}

	jsonToken(w, tok)
}

// GET /auth/facebook/login
func (h *OAuthHandler) FacebookLogin(w http.ResponseWriter, r *http.Request) {
	state := randomState()
	http.SetCookie(w, &http.Cookie{Name: "oauth_state", Value: state, Path: "/", HttpOnly: true, SameSite: http.SameSiteLaxMode})
	http.Redirect(w, r, h.Facebook.AuthCodeURL(state), http.StatusTemporaryRedirect)
}

// GET /auth/facebook/callback
func (h *OAuthHandler) FacebookCallback(w http.ResponseWriter, r *http.Request) {
	if err := validateState(r); err != nil {
		jsonError(w, "invalid state", http.StatusBadRequest)
		return
	}

	token, err := h.Facebook.Exchange(r.Context(), r.URL.Query().Get("code"))
	if err != nil {
		jsonError(w, "oauth exchange failed", http.StatusBadRequest)
		return
	}

	client := h.Facebook.Client(r.Context(), token)
	info, err := fetchFacebookUserInfo(client)
	if err != nil {
		jsonError(w, "failed to get user info", http.StatusInternalServerError)
		return
	}

	tok, err := h.Auth.LoginOAuth("facebook", info.ID, info.Email, info.Name)
	if err != nil {
		jsonError(w, "auth failed", http.StatusInternalServerError)
		return
	}

	jsonToken(w, tok)
}

type googleUserInfo struct {
	Sub   string `json:"sub"`
	Email string `json:"email"`
	Name  string `json:"name"`
}

func fetchGoogleUserInfo(client *http.Client) (*googleUserInfo, error) {
	resp, err := client.Get("https://www.googleapis.com/oauth2/v3/userinfo")
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	var info googleUserInfo
	err = json.NewDecoder(resp.Body).Decode(&info)
	return &info, err
}

type facebookUserInfo struct {
	ID    string `json:"id"`
	Email string `json:"email"`
	Name  string `json:"name"`
}

func fetchFacebookUserInfo(client *http.Client) (*facebookUserInfo, error) {
	resp, err := client.Get("https://graph.facebook.com/me?fields=id,email,name")
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(resp.Body)
	var info facebookUserInfo
	err = json.Unmarshal(body, &info)
	return &info, err
}

func randomState() string {
	b := make([]byte, 16)
	rand.Read(b)
	return hex.EncodeToString(b)
}

func validateState(r *http.Request) error {
	cookie, err := r.Cookie("oauth_state")
	if err != nil {
		return err
	}
	if cookie.Value != r.URL.Query().Get("state") {
		return http.ErrNoCookie
	}
	return nil
}
