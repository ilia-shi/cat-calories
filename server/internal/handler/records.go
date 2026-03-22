package handler

import (
	"encoding/json"
	"net/http"

	"cat-calories-server/internal/auth"
	"cat-calories-server/internal/model"
	"cat-calories-server/internal/usecase"

	"github.com/go-chi/chi/v5"
)

type RecordsHandler struct {
	Records *usecase.RecordsUseCase
}

func (h *RecordsHandler) List(w http.ResponseWriter, r *http.Request) {
	userID := auth.UserID(r.Context())
	resp, err := h.Records.List(userID)
	if err != nil {
		jsonError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	jsonResponse(w, http.StatusOK, resp)
}

func (h *RecordsHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID := auth.UserID(r.Context())

	var req model.CreateRecordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		jsonError(w, "invalid request body", http.StatusBadRequest)
		return
	}
	if req.Value == 0 {
		jsonError(w, "value is required", http.StatusBadRequest)
		return
	}

	record, err := h.Records.Create(userID, req)
	if err != nil {
		jsonError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	jsonResponse(w, http.StatusCreated, map[string]interface{}{"record": record})
}

func (h *RecordsHandler) Update(w http.ResponseWriter, r *http.Request) {
	userID := auth.UserID(r.Context())
	id := chi.URLParam(r, "id")

	var fields map[string]interface{}
	if err := json.NewDecoder(r.Body).Decode(&fields); err != nil {
		jsonError(w, "invalid request body", http.StatusBadRequest)
		return
	}

	record, err := h.Records.Update(userID, id, fields)
	if err != nil {
		if err.Error() == "not found" || err.Error() == "sql: no rows in result set" {
			jsonError(w, "Record not found", http.StatusNotFound)
			return
		}
		jsonError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	jsonResponse(w, http.StatusOK, map[string]interface{}{"record": record})
}

func (h *RecordsHandler) Delete(w http.ResponseWriter, r *http.Request) {
	userID := auth.UserID(r.Context())
	id := chi.URLParam(r, "id")

	err := h.Records.Delete(userID, id)
	if err != nil {
		if err.Error() == "not found" || err.Error() == "sql: no rows in result set" {
			jsonError(w, "Record not found", http.StatusNotFound)
			return
		}
		jsonError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	jsonResponse(w, http.StatusOK, map[string]interface{}{"deleted": true})
}

func (h *RecordsHandler) Home(w http.ResponseWriter, r *http.Request) {
	userID := auth.UserID(r.Context())
	resp, err := h.Records.HomeDashboard(userID)
	if err != nil {
		jsonError(w, err.Error(), http.StatusInternalServerError)
		return
	}
	jsonResponse(w, http.StatusOK, resp)
}

func jsonResponse(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}
