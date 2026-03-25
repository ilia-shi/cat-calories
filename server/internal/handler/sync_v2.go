package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"cat-calories-server/internal/auth"
	"cat-calories-server/internal/model"
	"cat-calories-server/internal/usecase"

	"github.com/jmoiron/sqlx"
)

type SyncV2Handler struct {
	Sync *usecase.SyncV2UseCase
}

// Push handles POST /api/v1/sync/push
func (h *SyncV2Handler) Push(w http.ResponseWriter, r *http.Request) {
	userID := auth.UserID(r.Context())
	if userID == "" {
		jsonError(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	var req model.PushRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "invalid request body", http.StatusBadRequest)
		return
	}

	log.Printf("sync_v2: push from user %s: type=%s entries=%d key=%s",
		userID, req.EntityType, len(req.Entries), req.IdempotencyKey)

	resp, err := h.Sync.Push(userID, req)
	if err != nil {
		log.Printf("sync_v2: push error for user %s: %v", userID, err)
		jsonError(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// Pull handles GET /api/v1/sync/pull?entity_type=...&since=...&limit=...
func (h *SyncV2Handler) Pull(w http.ResponseWriter, r *http.Request) {
	userID := auth.UserID(r.Context())
	if userID == "" {
		jsonError(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	entityType := r.URL.Query().Get("entity_type")
	sinceHLC := r.URL.Query().Get("since")
	limitStr := r.URL.Query().Get("limit")

	limit := 100
	if limitStr != "" {
		if v, err := strconv.Atoi(limitStr); err == nil && v > 0 {
			limit = v
		}
	}

	resp, err := h.Sync.Pull(userID, entityType, sinceHLC, limit)
	if err != nil {
		log.Printf("sync_v2: pull error for user %s: %v", userID, err)
		jsonError(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// --- Server Discovery ---

type DiscoveryHandler struct {
	ServerName    string
	ServerVersion string
	BaseURL       string
	AuthType      string // "casdoor" or "token"
	CasdoorIssuer   string
	CasdoorAuthURL  string
	CasdoorTokenURL string
	CasdoorClientID string
}

// SyncConfig handles GET /.well-known/sync-config
func (h *DiscoveryHandler) SyncConfig(w http.ResponseWriter, r *http.Request) {
	authCfg := map[string]interface{}{
		"type": h.AuthType,
	}
	if h.AuthType == "casdoor" {
		authCfg["issuer"] = h.CasdoorIssuer
		authCfg["auth_url"] = h.CasdoorAuthURL
		authCfg["token_url"] = h.CasdoorTokenURL
		authCfg["client_id"] = h.CasdoorClientID
	}

	resp := map[string]interface{}{
		"server_name":      h.ServerName,
		"server_version":   h.ServerVersion,
		"protocol_version": 2,
		"auth":             authCfg,
		"transports": map[string]interface{}{
			"rest": map[string]interface{}{
				"base_url": h.BaseURL,
			},
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// --- Health Check ---

type HealthHandler struct {
	DB      *sqlx.DB
	Version string
}

// Health handles GET /health with actual database connectivity check.
func (h *HealthHandler) Health(w http.ResponseWriter, r *http.Request) {
	dbOK := true
	if err := h.DB.Ping(); err != nil {
		dbOK = false
	}

	status := "ok"
	httpStatus := http.StatusOK
	if !dbOK {
		status = "degraded"
		httpStatus = http.StatusServiceUnavailable
	}

	resp := map[string]interface{}{
		"status":   status,
		"database": dbOK,
		"version":  h.Version,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(httpStatus)
	json.NewEncoder(w).Encode(resp)
}
