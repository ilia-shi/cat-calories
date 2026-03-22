package sqlite

import (
	"time"

	"cat-calories-server/internal/model"

	"github.com/jmoiron/sqlx"
)

type WakingPeriodRepo struct{ DB *sqlx.DB }

func (r *WakingPeriodRepo) Upsert(profileIDs []int64, wp model.WakingPeriod) error {
	if !isAllowed(profileIDs, wp.ProfileID) {
		return nil
	}
	_, err := r.DB.Exec(`
		INSERT INTO waking_periods (id, profile_id, description, calories_value, calories_limit_goal,
			expected_waking_time_sec, started_at, ended_at, created_at, updated_at, deleted_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
			description=excluded.description, calories_value=excluded.calories_value,
			calories_limit_goal=excluded.calories_limit_goal, expected_waking_time_sec=excluded.expected_waking_time_sec,
			started_at=excluded.started_at, ended_at=excluded.ended_at,
			updated_at=excluded.updated_at, deleted_at=excluded.deleted_at
		WHERE excluded.updated_at >= waking_periods.updated_at OR waking_periods.updated_at IS NULL
	`, wp.ID, wp.ProfileID, wp.Description, wp.CaloriesValue, wp.CaloriesLimitGoal,
		wp.ExpectedWakingTimeSec, wp.StartedAt, wp.EndedAt, wp.CreatedAt, wp.UpdatedAt, wp.DeletedAt)
	return err
}

func (r *WakingPeriodRepo) FindActiveByProfile(profileID int64) (*model.WakingPeriod, error) {
	var wp model.WakingPeriod
	err := r.DB.Get(&wp, "SELECT * FROM waking_periods WHERE profile_id = ? AND ended_at IS NULL AND deleted_at IS NULL ORDER BY started_at DESC LIMIT 1", profileID)
	if err != nil {
		return nil, err
	}
	return &wp, nil
}

func (r *WakingPeriodRepo) FindIDsByProfiles(profileIDs []int64) ([]int64, error) {
	if len(profileIDs) == 0 {
		return nil, nil
	}
	query, args, err := sqlx.In("SELECT id FROM waking_periods WHERE profile_id IN (?)", profileIDs)
	if err != nil {
		return nil, err
	}
	var ids []int64
	err = r.DB.Select(&ids, r.DB.Rebind(query), args...)
	return ids, err
}

func (r *WakingPeriodRepo) ChangedSince(profileIDs []int64, since time.Time) ([]model.WakingPeriod, error) {
	if len(profileIDs) == 0 {
		return nil, nil
	}
	query, args, err := sqlx.In("SELECT * FROM waking_periods WHERE profile_id IN (?) AND updated_at > ?", profileIDs, since)
	if err != nil {
		return nil, err
	}
	var out []model.WakingPeriod
	err = r.DB.Select(&out, r.DB.Rebind(query), args...)
	return out, err
}
