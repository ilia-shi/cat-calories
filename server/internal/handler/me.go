package handler

import (
	"encoding/json"
	"net/http"

	"cat-calories-server/internal/auth"
	"cat-calories-server/internal/repository"
)

type MeHandler struct {
	Users repository.UserRepository
}

// GET /api/me
func (h *MeHandler) Handle(w http.ResponseWriter, r *http.Request) {
	userID := auth.UserID(r.Context())
	if userID == "" {
		jsonError(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	user, err := h.Users.FindByID(userID)
	if err != nil {
		jsonError(w, "user not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}
