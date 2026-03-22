package sqlite

import (
	"cat-calories-server/internal/model"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type UserRepo struct{ DB *sqlx.DB }

func (r *UserRepo) FindByID(id string) (*model.User, error) {
	var u model.User
	err := r.DB.Get(&u, "SELECT * FROM users WHERE id = ?", id)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func (r *UserRepo) FindByProviderSubject(provider, subject string) (*model.User, error) {
	var u model.User
	err := r.DB.Get(&u, "SELECT * FROM users WHERE provider = ? AND subject = ?", provider, subject)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func (r *UserRepo) FindByEmail(email string) (*model.User, error) {
	var u model.User
	err := r.DB.Get(&u, "SELECT * FROM users WHERE provider = 'email' AND email = ?", email)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

func (r *UserRepo) Create(email, name, passwordHash, provider, subject string) (string, error) {
	id := uuid.New().String()
	_, err := r.DB.Exec(
		"INSERT INTO users (id, email, name, password_hash, provider, subject) VALUES (?, ?, ?, ?, ?, ?)",
		id, email, name, passwordHash, provider, subject,
	)
	if err != nil {
		return "", err
	}
	return id, nil
}
