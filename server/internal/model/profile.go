package model

import "time"

type Profile struct {
	ID                int64     `db:"id"                  json:"id"`
	UserID            string    `db:"user_id"             json:"user_id"`
	Name              string    `db:"name"                json:"name"`
	WakingTimeSeconds int       `db:"waking_time_seconds" json:"waking_time_seconds"`
	CaloriesLimitGoal int       `db:"calories_limit_goal" json:"calories_limit_goal"`
	CreatedAt         time.Time `db:"created_at"          json:"created_at"`
	UpdatedAt         time.Time `db:"updated_at"          json:"updated_at"`
}
