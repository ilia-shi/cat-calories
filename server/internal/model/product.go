package model

import "time"

type Product struct {
	ID               string     `db:"id"                 json:"id"`
	ProfileID        int64      `db:"profile_id"         json:"profile_id"`
	CategoryID       *string    `db:"category_id"        json:"category_id,omitempty"`
	Title            string     `db:"title"              json:"title"`
	Description      string     `db:"description"        json:"description"`
	Barcode          *string    `db:"barcode"            json:"barcode,omitempty"`
	CaloriesPer100g  *float64   `db:"calories_per_100g"  json:"calories_per_100g,omitempty"`
	ProteinsPer100g  *float64   `db:"proteins_per_100g"  json:"proteins_per_100g,omitempty"`
	FatsPer100g      *float64   `db:"fats_per_100g"      json:"fats_per_100g,omitempty"`
	CarbsPer100g     *float64   `db:"carbs_per_100g"     json:"carbs_per_100g,omitempty"`
	PackageWeightG   *float64   `db:"package_weight_g"   json:"package_weight_g,omitempty"`
	UsesCount        int        `db:"uses_count"         json:"uses_count"`
	LastUsedAt       *time.Time `db:"last_used_at"       json:"last_used_at,omitempty"`
	SortOrder        int        `db:"sort_order"         json:"sort_order"`
	CreatedAt        time.Time  `db:"created_at"         json:"created_at"`
	UpdatedAt        time.Time  `db:"updated_at"         json:"updated_at"`
	DeletedAt        *time.Time `db:"deleted_at"         json:"deleted_at,omitempty"`
}

type ProductCategory struct {
	ID        string     `db:"id"         json:"id"`
	ProfileID int64      `db:"profile_id" json:"profile_id"`
	Name      string     `db:"name"       json:"name"`
	IconName  string     `db:"icon_name"  json:"icon_name"`
	ColorHex  string     `db:"color_hex"  json:"color_hex"`
	SortOrder int        `db:"sort_order" json:"sort_order"`
	CreatedAt time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt time.Time  `db:"updated_at" json:"updated_at"`
	DeletedAt *time.Time `db:"deleted_at" json:"deleted_at,omitempty"`
}
