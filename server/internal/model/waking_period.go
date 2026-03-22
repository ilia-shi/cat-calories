package model

import "time"

type WakingPeriod struct {
	ID                      int64      `db:"id"                        json:"id"`
	ProfileID               int64      `db:"profile_id"               json:"profile_id"`
	Description             string     `db:"description"              json:"description"`
	CaloriesValue           float64    `db:"calories_value"           json:"calories_value"`
	CaloriesLimitGoal       int        `db:"calories_limit_goal"      json:"calories_limit_goal"`
	ExpectedWakingTimeSec   int        `db:"expected_waking_time_sec" json:"expected_waking_time_sec"`
	StartedAt               time.Time  `db:"started_at"               json:"started_at"`
	EndedAt                 *time.Time `db:"ended_at"                 json:"ended_at,omitempty"`
	CreatedAt               time.Time  `db:"created_at"               json:"created_at"`
	UpdatedAt               time.Time  `db:"updated_at"               json:"updated_at"`
	DeletedAt               *time.Time `db:"deleted_at"               json:"deleted_at,omitempty"`
}
