package handler_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"cat-calories-server/internal/auth"
	"cat-calories-server/internal/database"
	"cat-calories-server/internal/handler"
	"cat-calories-server/internal/repository/sqlite"
	"cat-calories-server/internal/usecase"

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/getkin/kin-openapi/openapi3filter"
	"github.com/getkin/kin-openapi/routers"
	"github.com/getkin/kin-openapi/routers/gorillamux"
	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	_ "github.com/mattn/go-sqlite3"
)

const testSecret = "test-secret-key"

// setupTestServer creates an in-memory SQLite database, runs migrations,
// seeds a test user and profile, wires up the chi router with all handlers,
// and returns an httptest.Server plus the auth token.
func setupTestServer(t *testing.T) (*httptest.Server, string) {
	t.Helper()

	// Open in-memory SQLite without WAL (WAL is not supported for :memory:)
	db, err := sqlx.Open("sqlite3", ":memory:?_foreign_keys=on")
	if err != nil {
		t.Fatalf("open db: %v", err)
	}
	t.Cleanup(func() { db.Close() })

	if err := database.Migrate(db); err != nil {
		t.Fatalf("migrate: %v", err)
	}

	// Create test user
	userID := uuid.New().String()
	_, err = db.Exec(
		"INSERT INTO users (id, email, name, password_hash, provider, subject) VALUES (?, ?, ?, ?, ?, ?)",
		userID, "test@example.com", "Test User", "", "email", "test@example.com",
	)
	if err != nil {
		t.Fatalf("insert user: %v", err)
	}

	// Create test profile
	_, err = db.Exec(
		"INSERT INTO profiles (user_id, name, calories_limit_goal) VALUES (?, ?, ?)",
		userID, "Default", 2000,
	)
	if err != nil {
		t.Fatalf("insert profile: %v", err)
	}

	// Generate auth token
	token, err := auth.GenerateToken(testSecret, userID)
	if err != nil {
		t.Fatalf("generate token: %v", err)
	}

	// Repositories
	profileRepo := &sqlite.ProfileRepo{DB: db}
	calorieItemRepo := &sqlite.CalorieItemRepo{DB: db}
	wakingPeriodRepo := &sqlite.WakingPeriodRepo{DB: db}

	// Use case
	recordsUC := &usecase.RecordsUseCase{
		Profiles:      profileRepo,
		CalorieItems:  calorieItemRepo,
		WakingPeriods: wakingPeriodRepo,
	}

	// Handler
	recordsHandler := &handler.RecordsHandler{Records: recordsUC}

	// Router (same structure as main.go for the API routes)
	r := chi.NewRouter()
	r.Group(func(r chi.Router) {
		r.Use(auth.Middleware(testSecret))
		r.Get("/api/records", recordsHandler.List)
		r.Post("/api/records", recordsHandler.Create)
		r.Put("/api/records/{id}", recordsHandler.Update)
		r.Delete("/api/records/{id}", recordsHandler.Delete)
		r.Get("/api/home", recordsHandler.Home)
	})

	ts := httptest.NewServer(r)
	t.Cleanup(ts.Close)

	return ts, token
}

// loadOpenAPIValidator loads the OpenAPI spec and returns a router for validation.
func loadOpenAPIValidator(t *testing.T) routers.Router {
	t.Helper()

	specPath := "../../../api/openapi.yaml"
	data, err := os.ReadFile(specPath)
	if err != nil {
		t.Fatalf("read openapi spec: %v", err)
	}

	loader := openapi3.NewLoader()
	doc, err := loader.LoadFromData(data)
	if err != nil {
		t.Fatalf("load openapi spec: %v", err)
	}

	if err := doc.Validate(context.Background()); err != nil {
		t.Fatalf("validate openapi spec: %v", err)
	}

	router, err := gorillamux.NewRouter(doc)
	if err != nil {
		t.Fatalf("create openapi router: %v", err)
	}

	return router
}

// validateResponse validates an HTTP response against the OpenAPI spec.
func validateResponse(t *testing.T, router routers.Router, req *http.Request, resp *http.Response, body []byte) {
	t.Helper()

	// Create a clean request with a spec-compatible URL for route matching
	specReq, _ := http.NewRequest(req.Method, "http://localhost:8080"+req.URL.Path, nil)
	specReq.Header = req.Header

	route, pathParams, err := router.FindRoute(specReq)
	if err != nil {
		t.Fatalf("find route for %s %s: %v", req.Method, req.URL.Path, err)
	}

	input := &openapi3filter.RequestValidationInput{
		Request:    specReq,
		PathParams: pathParams,
		Route:      route,
		Options: &openapi3filter.Options{
			AuthenticationFunc: openapi3filter.NoopAuthenticationFunc,
		},
	}

	responseInput := &openapi3filter.ResponseValidationInput{
		RequestValidationInput: input,
		Status:                 resp.StatusCode,
		Header:                 resp.Header,
		Body:                   io.NopCloser(bytes.NewReader(body)),
		Options: &openapi3filter.Options{
			AuthenticationFunc: openapi3filter.NoopAuthenticationFunc,
		},
	}

	if err := openapi3filter.ValidateResponse(context.Background(), responseInput); err != nil {
		t.Errorf("response validation failed for %s %s (status %d):\n%v\nBody: %s",
			req.Method, req.URL.Path, resp.StatusCode, err, string(body))
	}
}

// doRequest performs an HTTP request against the test server and returns the response.
func doRequest(t *testing.T, method, url, token string, body interface{}) (*http.Response, []byte, *http.Request) {
	t.Helper()

	var reqBody io.Reader
	if body != nil {
		data, err := json.Marshal(body)
		if err != nil {
			t.Fatalf("marshal request body: %v", err)
		}
		reqBody = bytes.NewReader(data)
	}

	req, err := http.NewRequest(method, url, reqBody)
	if err != nil {
		t.Fatalf("create request: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("do request: %v", err)
	}

	respBody, err := io.ReadAll(resp.Body)
	resp.Body.Close()
	if err != nil {
		t.Fatalf("read response body: %v", err)
	}

	return resp, respBody, req
}

func TestRecordsAPI_OpenAPIValidation(t *testing.T) {
	ts, token := setupTestServer(t)
	router := loadOpenAPIValidator(t)

	// --- 1. GET /api/records (empty list initially) ---
	t.Run("GET /api/records empty", func(t *testing.T) {
		resp, body, req := doRequest(t, "GET", ts.URL+"/api/records", token, nil)

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("expected status 200, got %d: %s", resp.StatusCode, string(body))
		}

		validateResponse(t, router, req, resp, body)

		var result struct {
			Records []interface{} `json:"records"`
		}
		if err := json.Unmarshal(body, &result); err != nil {
			t.Fatalf("unmarshal: %v", err)
		}
		if len(result.Records) != 0 {
			t.Errorf("expected 0 records, got %d", len(result.Records))
		}
	})

	// --- 2. POST /api/records (create a record) ---
	var createdID string
	t.Run("POST /api/records", func(t *testing.T) {
		desc := "Chicken breast"
		weight := 200.0
		createBody := map[string]interface{}{
			"value":        350.5,
			"description":  desc,
			"weight_grams": weight,
		}

		resp, body, req := doRequest(t, "POST", ts.URL+"/api/records", token, createBody)

		if resp.StatusCode != http.StatusCreated {
			t.Fatalf("expected status 201, got %d: %s", resp.StatusCode, string(body))
		}

		validateResponse(t, router, req, resp, body)

		var result struct {
			Record struct {
				ID          string   `json:"id"`
				Value       float64  `json:"value"`
				Description *string  `json:"description"`
				WeightGrams *float64 `json:"weight_grams"`
			} `json:"record"`
		}
		if err := json.Unmarshal(body, &result); err != nil {
			t.Fatalf("unmarshal: %v", err)
		}
		if result.Record.ID == "" {
			t.Fatal("expected record ID to be set")
		}
		if result.Record.Value != 350.5 {
			t.Errorf("expected value 350.5, got %f", result.Record.Value)
		}
		if result.Record.Description == nil || *result.Record.Description != desc {
			t.Errorf("expected description %q, got %v", desc, result.Record.Description)
		}
		if result.Record.WeightGrams == nil || *result.Record.WeightGrams != weight {
			t.Errorf("expected weight_grams %f, got %v", weight, result.Record.WeightGrams)
		}

		createdID = result.Record.ID
	})

	// --- 3. GET /api/records (verify record appears) ---
	t.Run("GET /api/records with record", func(t *testing.T) {
		resp, body, req := doRequest(t, "GET", ts.URL+"/api/records", token, nil)

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("expected status 200, got %d: %s", resp.StatusCode, string(body))
		}

		validateResponse(t, router, req, resp, body)

		var result struct {
			Records []struct {
				ID string `json:"id"`
			} `json:"records"`
		}
		if err := json.Unmarshal(body, &result); err != nil {
			t.Fatalf("unmarshal: %v", err)
		}
		if len(result.Records) != 1 {
			t.Fatalf("expected 1 record, got %d", len(result.Records))
		}
		if result.Records[0].ID != createdID {
			t.Errorf("expected record ID %s, got %s", createdID, result.Records[0].ID)
		}
	})

	// --- 4. PUT /api/records/{id} (update the record) ---
	t.Run("PUT /api/records/{id}", func(t *testing.T) {
		updateBody := map[string]interface{}{
			"value":       400.0,
			"description": "Grilled chicken breast",
		}

		resp, body, req := doRequest(t, "PUT", fmt.Sprintf("%s/api/records/%s", ts.URL, createdID), token, updateBody)

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("expected status 200, got %d: %s", resp.StatusCode, string(body))
		}

		validateResponse(t, router, req, resp, body)

		var result struct {
			Record struct {
				ID          string  `json:"id"`
				Value       float64 `json:"value"`
				Description *string `json:"description"`
			} `json:"record"`
		}
		if err := json.Unmarshal(body, &result); err != nil {
			t.Fatalf("unmarshal: %v", err)
		}
		if result.Record.Value != 400.0 {
			t.Errorf("expected value 400.0, got %f", result.Record.Value)
		}
		expected := "Grilled chicken breast"
		if result.Record.Description == nil || *result.Record.Description != expected {
			t.Errorf("expected description %q, got %v", expected, result.Record.Description)
		}
	})

	// --- 5. DELETE /api/records/{id} (delete the record) ---
	t.Run("DELETE /api/records/{id}", func(t *testing.T) {
		resp, body, req := doRequest(t, "DELETE", fmt.Sprintf("%s/api/records/%s", ts.URL, createdID), token, nil)

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("expected status 200, got %d: %s", resp.StatusCode, string(body))
		}

		validateResponse(t, router, req, resp, body)

		var result struct {
			Deleted bool `json:"deleted"`
		}
		if err := json.Unmarshal(body, &result); err != nil {
			t.Fatalf("unmarshal: %v", err)
		}
		if !result.Deleted {
			t.Error("expected deleted to be true")
		}
	})

	// --- 6. GET /api/home (verify dashboard response) ---
	t.Run("GET /api/home", func(t *testing.T) {
		resp, body, req := doRequest(t, "GET", ts.URL+"/api/home", token, nil)

		if resp.StatusCode != http.StatusOK {
			t.Fatalf("expected status 200, got %d: %s", resp.StatusCode, string(body))
		}

		validateResponse(t, router, req, resp, body)

		var result struct {
			Profile struct {
				Name              string  `json:"name"`
				CaloriesLimitGoal float64 `json:"calories_limit_goal"`
			} `json:"profile"`
			Rolling24h  float64       `json:"rolling_24h"`
			Today       float64       `json:"today"`
			Yesterday   float64       `json:"yesterday"`
			Avg7Days    float64       `json:"avg_7_days"`
			RecentMeals []interface{} `json:"recent_meals"`
		}
		if err := json.Unmarshal(body, &result); err != nil {
			t.Fatalf("unmarshal: %v", err)
		}
		if result.Profile.Name != "Default" {
			t.Errorf("expected profile name 'Default', got %q", result.Profile.Name)
		}
		if result.Profile.CaloriesLimitGoal != 2000 {
			t.Errorf("expected calories_limit_goal 2000, got %f", result.Profile.CaloriesLimitGoal)
		}
	})
}
