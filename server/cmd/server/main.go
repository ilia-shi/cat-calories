package main

import (
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"

	"cat-calories-server/internal/auth"
	"cat-calories-server/internal/config"
	"cat-calories-server/internal/database"
	"cat-calories-server/internal/handler"
	"cat-calories-server/internal/model"
	"cat-calories-server/internal/repository/sqlite"
	"cat-calories-server/internal/usecase"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func main() {
	// Set up logging to both stdout and file
	if logDir := os.Getenv("LOG_DIR"); logDir != "" {
		os.MkdirAll(logDir, 0755)
		logFile, err := os.OpenFile(filepath.Join(logDir, "server.log"), os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
		if err == nil {
			log.SetOutput(io.MultiWriter(os.Stdout, logFile))
		}
	}

	cfg := config.Load()

	db, err := database.Open(cfg.DatabasePath)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer db.Close()

	if err := database.Migrate(db); err != nil {
		log.Fatalf("migrate: %v", err)
	}

	// Repositories
	userRepo := &sqlite.UserRepo{DB: db}
	profileRepo := &sqlite.ProfileRepo{DB: db}
	calorieItemRepo := &sqlite.CalorieItemRepo{DB: db}
	productRepo := &sqlite.ProductRepo{DB: db}
	productCategoryRepo := &sqlite.ProductCategoryRepo{DB: db}
	wakingPeriodRepo := &sqlite.WakingPeriodRepo{DB: db}
	syncEntryRepo := &sqlite.SyncEntryRepo{DB: db, HLC: model.NewHLCGenerator()}

	// Use cases
	authUC := &usecase.AuthUseCase{Users: userRepo, Secret: cfg.ServerSecret}
	syncUC := &usecase.SyncUseCase{
		Profiles:          profileRepo,
		CalorieItems:      calorieItemRepo,
		Products:          productRepo,
		ProductCategories: productCategoryRepo,
		WakingPeriods:     wakingPeriodRepo,
	}
	syncV2UC := &usecase.SyncV2UseCase{SyncEntries: syncEntryRepo}

	// Records use case (web frontend)
	recordsUC := &usecase.RecordsUseCase{
		Profiles:      profileRepo,
		CalorieItems:  calorieItemRepo,
		WakingPeriods: wakingPeriodRepo,
	}

	// Casdoor auth (optional — only enabled if CASDOOR_CLIENT_ID is set)
	var casdoorAuth *auth.CasdoorAuth
	authType := "token"
	if cfg.CasdoorClientID != "" {
		casdoorAuth = auth.NewCasdoorAuth(auth.CasdoorConfig{
			Endpoint:     cfg.CasdoorEndpoint,
			ClientID:     cfg.CasdoorClientID,
			ClientSecret: cfg.CasdoorClientSecret,
			Organization: cfg.CasdoorOrganization,
			Application:  cfg.CasdoorApplication,
			Certificate:  cfg.CasdoorCertificate,
		})
		authType = "casdoor"
		log.Printf("Casdoor auth enabled: endpoint=%s org=%s app=%s", cfg.CasdoorEndpoint, cfg.CasdoorOrganization, cfg.CasdoorApplication)
	}

	// User lookup for Casdoor: find or create user by provider/subject
	userLookup := func(provider, subject string) (string, error) {
		u, err := userRepo.FindByProviderSubject(provider, subject)
		if err != nil {
			return "", err
		}
		if u != nil {
			return u.ID, nil
		}
		// Auto-create user on first Casdoor login
		id, err := userRepo.Create(subject+"@casdoor", subject, "", provider, subject)
		if err != nil {
			return "", err
		}
		return id, nil
	}

	// Auth middleware: combined if Casdoor is enabled, old-style otherwise
	var authMiddleware func(http.Handler) http.Handler
	if casdoorAuth != nil {
		authMiddleware = auth.CombinedMiddleware(cfg.ServerSecret, casdoorAuth, userLookup)
	} else {
		authMiddleware = auth.Middleware(cfg.ServerSecret)
	}

	// Handlers
	authHandler := &handler.AuthHandler{Auth: authUC}
	meHandler := &handler.MeHandler{Users: userRepo}
	oauthHandler := &handler.OAuthHandler{
		Auth:     authUC,
		Google:   auth.GoogleOAuthConfig(cfg.GoogleClientID, cfg.GoogleClientSecret, cfg.GoogleRedirectURL),
		Facebook: auth.FacebookOAuthConfig(cfg.FacebookClientID, cfg.FacebookClientSecret, cfg.FacebookRedirectURL),
	}

	syncHandler := &handler.SyncHandler{Sync: syncUC}
	syncV2Handler := &handler.SyncV2Handler{Sync: syncV2UC}
	recordsHandler := &handler.RecordsHandler{Records: recordsUC}
	healthHandler := &handler.HealthHandler{DB: db, Version: cfg.ServerVersion}
	discoveryHandler := &handler.DiscoveryHandler{
		ServerName:    cfg.ServerName,
		ServerVersion: cfg.ServerVersion,
		BaseURL:       cfg.ServerBaseURL,
		AuthType:      authType,
	}
	if casdoorAuth != nil {
		discoveryHandler.CasdoorIssuer = cfg.CasdoorEndpoint
		discoveryHandler.CasdoorAuthURL = cfg.CasdoorEndpoint + "/login/oauth/authorize"
		discoveryHandler.CasdoorTokenURL = cfg.CasdoorEndpoint + "/api/login/oauth/access_token"
		discoveryHandler.CasdoorClientID = cfg.CasdoorClientID
	}

	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	// Pages
	r.Get("/", handler.Home)
	r.Get("/login", handler.Login)

	// Public: Auth routes
	r.Post("/auth/register", authHandler.Register)
	r.Post("/auth/login", authHandler.Login)
	r.Get("/auth/google/login", oauthHandler.GoogleLogin)
	r.Get("/auth/google/callback", oauthHandler.GoogleCallback)
	r.Get("/auth/facebook/login", oauthHandler.FacebookLogin)
	r.Get("/auth/facebook/callback", oauthHandler.FacebookCallback)

	// Public: Health check (with DB connectivity)
	r.Get("/health", healthHandler.Health)

	// Public: Server discovery
	r.Get("/.well-known/sync-config", discoveryHandler.SyncConfig)

	// Protected: Legacy API (web frontend + old mobile sync)
	r.Group(func(r chi.Router) {
		r.Use(authMiddleware)
		r.Get("/api/me", meHandler.Handle)
		r.Post("/api/sync", syncHandler.Handle)
		r.Get("/api/records", recordsHandler.List)
		r.Post("/api/records", recordsHandler.Create)
		r.Put("/api/records/{id}", recordsHandler.Update)
		r.Delete("/api/records/{id}", recordsHandler.Delete)
		r.Get("/api/home", recordsHandler.Home)
	})

	// Protected: Sync v2 API (new mobile sync protocol)
	r.Group(func(r chi.Router) {
		r.Use(authMiddleware)
		r.Post("/api/v1/sync/push", syncV2Handler.Push)
		r.Get("/api/v1/sync/pull", syncV2Handler.Pull)
	})

	// Serve web frontend static files if configured
	if cfg.WebDistPath != "" {
		fs := http.FileServer(http.Dir(cfg.WebDistPath))
		r.Get("/*", func(w http.ResponseWriter, r *http.Request) {
			path := filepath.Join(cfg.WebDistPath, r.URL.Path)
			if _, err := os.Stat(path); os.IsNotExist(err) {
				http.ServeFile(w, r, filepath.Join(cfg.WebDistPath, "index.html"))
				return
			}
			fs.ServeHTTP(w, r)
		})
	}

	log.Printf("server listening on :%s", cfg.ServerPort)
	if err := http.ListenAndServe(":"+cfg.ServerPort, r); err != nil {
		log.Fatalf("server: %v", err)
	}
}
