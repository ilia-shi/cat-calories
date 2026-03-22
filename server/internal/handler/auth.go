package handler

import (
	"encoding/json"
	"errors"
	"net/http"

	"cat-calories-server/internal/usecase"
)

type AuthHandler struct {
	Auth *usecase.AuthUseCase
}

type emailRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
	Name     string `json:"name"`
}

// POST /auth/register
func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req emailRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "invalid request", http.StatusBadRequest)
		return
	}

	token, err := h.Auth.Register(req.Email, req.Password, req.Name)
	if err != nil {
		switch {
		case errors.Is(err, usecase.ErrEmailRequired):
			jsonError(w, err.Error(), http.StatusBadRequest)
		case errors.Is(err, usecase.ErrEmailTaken):
			jsonError(w, err.Error(), http.StatusConflict)
		default:
			jsonError(w, "internal error", http.StatusInternalServerError)
		}
		return
	}

	jsonToken(w, token)
}

// POST /auth/login
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req emailRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "invalid request", http.StatusBadRequest)
		return
	}

	token, err := h.Auth.Login(req.Email, req.Password)
	if err != nil {
		switch {
		case errors.Is(err, usecase.ErrEmailRequired):
			jsonError(w, err.Error(), http.StatusBadRequest)
		case errors.Is(err, usecase.ErrInvalidCredentials):
			jsonError(w, err.Error(), http.StatusUnauthorized)
		default:
			jsonError(w, "internal error", http.StatusInternalServerError)
		}
		return
	}

	jsonToken(w, token)
}

func jsonToken(w http.ResponseWriter, token string) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"token": token})
}

func jsonError(w http.ResponseWriter, msg string, code int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(map[string]string{"error": msg})
}
