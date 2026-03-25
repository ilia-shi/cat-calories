package auth

import (
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// CasdoorConfig holds the Casdoor server connection parameters.
type CasdoorConfig struct {
	Endpoint     string // e.g. "http://casdoor:8000"
	ClientID     string
	ClientSecret string
	Organization string
	Application  string
	// Certificate is the Casdoor application's public certificate (PEM).
	// If empty, it will be fetched from Casdoor's API on first use.
	Certificate string
}

// CasdoorAuth validates JWTs issued by Casdoor.
type CasdoorAuth struct {
	config    CasdoorConfig
	publicKey *rsa.PublicKey
	mu        sync.RWMutex
}

func NewCasdoorAuth(cfg CasdoorConfig) *CasdoorAuth {
	return &CasdoorAuth{config: cfg}
}

// CasdoorClaims extends JWT standard claims with Casdoor-specific fields.
type CasdoorClaims struct {
	jwt.RegisteredClaims
	Owner string `json:"owner,omitempty"`
	Name  string `json:"name,omitempty"`
	Email string `json:"email,omitempty"`
}

// ValidateToken checks a Casdoor JWT and returns the user subject (owner/name).
func (ca *CasdoorAuth) ValidateToken(tokenStr string) (*CasdoorClaims, error) {
	key, err := ca.getPublicKey()
	if err != nil {
		return nil, fmt.Errorf("casdoor public key: %w", err)
	}

	token, err := jwt.ParseWithClaims(tokenStr, &CasdoorClaims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return key, nil
	})
	if err != nil {
		return nil, fmt.Errorf("invalid token: %w", err)
	}

	claims, ok := token.Claims.(*CasdoorClaims)
	if !ok || !token.Valid {
		return nil, fmt.Errorf("invalid token claims")
	}

	return claims, nil
}

// getPublicKey returns the cached public key or fetches it from Casdoor.
func (ca *CasdoorAuth) getPublicKey() (*rsa.PublicKey, error) {
	ca.mu.RLock()
	if ca.publicKey != nil {
		defer ca.mu.RUnlock()
		return ca.publicKey, nil
	}
	ca.mu.RUnlock()

	ca.mu.Lock()
	defer ca.mu.Unlock()

	// Double-check after acquiring write lock.
	if ca.publicKey != nil {
		return ca.publicKey, nil
	}

	certPEM := ca.config.Certificate
	if certPEM == "" {
		var err error
		certPEM, err = ca.fetchCertificate()
		if err != nil {
			return nil, err
		}
	}

	key, err := parseCertificatePEM(certPEM)
	if err != nil {
		return nil, err
	}

	ca.publicKey = key
	return ca.publicKey, nil
}

// fetchCertificate gets the application's public cert from Casdoor's API.
func (ca *CasdoorAuth) fetchCertificate() (string, error) {
	url := fmt.Sprintf("%s/api/get-application?id=%s/%s&clientId=%s&clientSecret=%s",
		strings.TrimRight(ca.config.Endpoint, "/"),
		ca.config.Organization, ca.config.Application,
		ca.config.ClientID, ca.config.ClientSecret)

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Get(url)
	if err != nil {
		return "", fmt.Errorf("fetch casdoor app: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("read casdoor response: %w", err)
	}

	var result struct {
		Data json.RawMessage `json:"data"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", fmt.Errorf("parse casdoor response: %w", err)
	}

	var app struct {
		Cert string `json:"cert"`
	}
	if err := json.Unmarshal(result.Data, &app); err != nil {
		return "", fmt.Errorf("parse casdoor app: %w", err)
	}

	if app.Cert == "" {
		return "", fmt.Errorf("casdoor app has no certificate configured")
	}

	// Fetch the actual certificate PEM from Casdoor
	certURL := fmt.Sprintf("%s/api/get-cert?id=%s/%s&clientId=%s&clientSecret=%s",
		strings.TrimRight(ca.config.Endpoint, "/"),
		ca.config.Organization, app.Cert,
		ca.config.ClientID, ca.config.ClientSecret)

	certResp, err := client.Get(certURL)
	if err != nil {
		return "", fmt.Errorf("fetch casdoor cert: %w", err)
	}
	defer certResp.Body.Close()

	certBody, err := io.ReadAll(certResp.Body)
	if err != nil {
		return "", fmt.Errorf("read cert response: %w", err)
	}

	var certResult struct {
		Data struct {
			Certificate string `json:"certificate"`
		} `json:"data"`
	}
	if err := json.Unmarshal(certBody, &certResult); err != nil {
		return "", fmt.Errorf("parse cert response: %w", err)
	}

	return certResult.Data.Certificate, nil
}

func parseCertificatePEM(certPEM string) (*rsa.PublicKey, error) {
	// Try parsing as a certificate first
	block, _ := pem.Decode([]byte(certPEM))
	if block == nil {
		return nil, fmt.Errorf("failed to decode PEM block")
	}

	if block.Type == "CERTIFICATE" {
		cert, err := x509.ParseCertificate(block.Bytes)
		if err != nil {
			return nil, fmt.Errorf("parse certificate: %w", err)
		}
		rsaKey, ok := cert.PublicKey.(*rsa.PublicKey)
		if !ok {
			return nil, fmt.Errorf("certificate key is not RSA")
		}
		return rsaKey, nil
	}

	// Try as a raw public key
	pub, err := x509.ParsePKIXPublicKey(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("parse public key: %w", err)
	}
	rsaKey, ok := pub.(*rsa.PublicKey)
	if !ok {
		return nil, fmt.Errorf("key is not RSA")
	}
	return rsaKey, nil
}
