package handler

import (
	"encoding/json"
	"log"
	"net/http"

	"cat-calories-server/internal/auth"
	"cat-calories-server/internal/model"
	"cat-calories-server/internal/usecase"
)

type SyncHandler struct {
	Sync *usecase.SyncUseCase
}

// POST /api/sync
func (h *SyncHandler) Handle(w http.ResponseWriter, r *http.Request) {
	userID := auth.UserID(r.Context())
	if userID == "" {
		jsonError(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req model.SyncRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "invalid request body", http.StatusBadRequest)
		return
	}

	log.Printf("sync request from user %s: %d profiles, %d waking_periods, %d categories, %d products, %d items",
		userID, len(req.Profiles), len(req.WakingPeriods), len(req.ProductCategories), len(req.Products), len(req.CalorieItems))
	for i, p := range req.Profiles {
		log.Printf("  profile[%d]: id=%d name=%q goal=%d", i, p.ID, p.Name, p.CaloriesLimitGoal)
	}
	for i, wp := range req.WakingPeriods {
		log.Printf("  waking_period[%d]: id=%d profile_id=%d", i, wp.ID, wp.ProfileID)
	}
	for i, p := range req.Products {
		log.Printf("  product[%d]: id=%s profile_id=%d", i, p.ID, p.ProfileID)
	}

	resp, err := h.Sync.Process(userID, req)
	if err != nil {
		log.Printf("sync error for user %s: %v", userID, err)
		jsonError(w, "sync failed", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
