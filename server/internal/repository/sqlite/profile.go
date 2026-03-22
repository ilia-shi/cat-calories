package sqlite

import (
	"time"

	"cat-calories-server/internal/model"

	"github.com/jmoiron/sqlx"
)

type ProfileRepo struct{ DB *sqlx.DB }

func (r *ProfileRepo) FindByUser(userID string) ([]int64, error) {
	var ids []int64
	err := r.DB.Select(&ids, "SELECT id FROM profiles WHERE user_id = ?", userID)
	return ids, err
}

func (r *ProfileRepo) FindByID(id int64) (*model.Profile, error) {
	var p model.Profile
	err := r.DB.Get(&p, "SELECT * FROM profiles WHERE id = ?", id)
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *ProfileRepo) Upsert(userID string, p model.Profile) error {
	_, err := r.DB.Exec(`
		INSERT INTO profiles (id, user_id, name, waking_time_seconds, calories_limit_goal, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
			name=excluded.name,
			waking_time_seconds=excluded.waking_time_seconds,
			calories_limit_goal=excluded.calories_limit_goal,
			updated_at=excluded.updated_at
		WHERE excluded.updated_at >= profiles.updated_at OR profiles.updated_at IS NULL
	`, p.ID, userID, p.Name, p.WakingTimeSeconds, p.CaloriesLimitGoal, p.CreatedAt, p.UpdatedAt)
	return err
}

func (r *ProfileRepo) ChangedSince(userID string, since time.Time) ([]model.Profile, error) {
	var out []model.Profile
	err := r.DB.Select(&out, "SELECT * FROM profiles WHERE user_id = ? AND updated_at > ?", userID, since)
	return out, err
}
