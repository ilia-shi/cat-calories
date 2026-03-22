package model

import "time"

type User struct {
	ID           string    `db:"id"            json:"id"`
	Email        string    `db:"email"         json:"email"`
	Name         string    `db:"name"          json:"name"`
	PasswordHash string    `db:"password_hash" json:"-"`
	Provider     string    `db:"provider"      json:"provider"`
	Subject      string    `db:"subject"       json:"-"`
	CreatedAt    time.Time `db:"created_at"    json:"created_at"`
	UpdatedAt    time.Time `db:"updated_at"    json:"updated_at"`
}
