package model

import "time"

type CalorieItem struct {
	ID             string     `db:"id"               json:"id"`
	ProfileID      int64      `db:"profile_id"       json:"profile_id"`
	WakingPeriodID *int64     `db:"waking_period_id" json:"waking_period_id,omitempty"`
	ProductID      *string    `db:"product_id"       json:"product_id,omitempty"`
	Value          float64    `db:"value"            json:"value"`
	Description    string     `db:"description"      json:"description"`
	SortOrder      int        `db:"sort_order"       json:"sort_order"`
	WeightGrams    *float64   `db:"weight_grams"     json:"weight_grams,omitempty"`
	ProteinGrams   *float64   `db:"protein_grams"    json:"protein_grams,omitempty"`
	FatGrams       *float64   `db:"fat_grams"        json:"fat_grams,omitempty"`
	CarbGrams      *float64   `db:"carb_grams"       json:"carb_grams,omitempty"`
	EatenAt        time.Time  `db:"eaten_at"         json:"eaten_at"`
	CreatedAt      time.Time  `db:"created_at"       json:"created_at"`
	UpdatedAt      time.Time  `db:"updated_at"       json:"updated_at"`
	DeletedAt      *time.Time `db:"deleted_at"       json:"deleted_at,omitempty"`
}
