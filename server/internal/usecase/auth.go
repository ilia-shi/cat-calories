package usecase

import (
	"errors"
	"strings"

	"cat-calories-server/internal/auth"
	"cat-calories-server/internal/repository"

	"golang.org/x/crypto/bcrypt"
)

var (
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrEmailRequired      = errors.New("email and password are required")
	ErrEmailTaken         = errors.New("email already registered")
)

type AuthUseCase struct {
	Users  repository.UserRepository
	Secret string
}

func (uc *AuthUseCase) Register(email, password, name string) (string, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	if email == "" || password == "" {
		return "", ErrEmailRequired
	}

	if u, _ := uc.Users.FindByEmail(email); u != nil {
		return "", ErrEmailTaken
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}

	userID, err := uc.Users.Create(email, name, string(hash), "email", email)
	if err != nil {
		return "", err
	}

	return auth.GenerateToken(uc.Secret, userID)
}

func (uc *AuthUseCase) Login(email, password string) (string, error) {
	email = strings.TrimSpace(strings.ToLower(email))
	if email == "" || password == "" {
		return "", ErrEmailRequired
	}

	user, err := uc.Users.FindByEmail(email)
	if err != nil {
		return "", ErrInvalidCredentials
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return "", ErrInvalidCredentials
	}

	return auth.GenerateToken(uc.Secret, user.ID)
}

func (uc *AuthUseCase) LoginOAuth(provider, subject, email, name string) (string, error) {
	user, err := uc.Users.FindByProviderSubject(provider, subject)
	if err != nil {
		userID, err := uc.Users.Create(email, name, "", provider, subject)
		if err != nil {
			return "", err
		}
		return auth.GenerateToken(uc.Secret, userID)
	}
	return auth.GenerateToken(uc.Secret, user.ID)
}
