package config

import "os"

type Config struct {
	DatabasePath string
	ServerPort   string
	ServerSecret string
	WebDistPath  string

	GoogleClientID     string
	GoogleClientSecret string
	GoogleRedirectURL  string

	FacebookClientID     string
	FacebookClientSecret string
	FacebookRedirectURL  string

	// Casdoor OAuth
	CasdoorEndpoint     string
	CasdoorClientID     string
	CasdoorClientSecret string
	CasdoorOrganization string
	CasdoorApplication  string
	CasdoorCertificate  string

	// Server identity for discovery
	ServerName    string
	ServerVersion string
	ServerBaseURL string
}

func Load() *Config {
	return &Config{
		DatabasePath:         env("DATABASE_PATH", "./data.db"),
		ServerPort:           env("SERVER_PORT", "8080"),
		ServerSecret:         env("SERVER_SECRET", ""),
		WebDistPath:          os.Getenv("WEB_DIST_PATH"),
		GoogleClientID:       os.Getenv("GOOGLE_CLIENT_ID"),
		GoogleClientSecret:   os.Getenv("GOOGLE_CLIENT_SECRET"),
		GoogleRedirectURL:    env("GOOGLE_REDIRECT_URL", "http://localhost:8080/auth/google/callback"),
		FacebookClientID:     os.Getenv("FACEBOOK_CLIENT_ID"),
		FacebookClientSecret: os.Getenv("FACEBOOK_CLIENT_SECRET"),
		FacebookRedirectURL:  env("FACEBOOK_REDIRECT_URL", "http://localhost:8080/auth/facebook/callback"),

		CasdoorEndpoint:     env("CASDOOR_ENDPOINT", "http://casdoor:8000"),
		CasdoorClientID:     os.Getenv("CASDOOR_CLIENT_ID"),
		CasdoorClientSecret: os.Getenv("CASDOOR_CLIENT_SECRET"),
		CasdoorOrganization: env("CASDOOR_ORGANIZATION", "built-in"),
		CasdoorApplication:  env("CASDOOR_APPLICATION", "cat-calories"),
		CasdoorCertificate:  os.Getenv("CASDOOR_CERTIFICATE"),

		ServerName:    env("SERVER_NAME", "Cat Calories Sync"),
		ServerVersion: env("SERVER_VERSION", "2.0.0"),
		ServerBaseURL: env("SERVER_BASE_URL", "http://localhost:8080"),
	}
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
