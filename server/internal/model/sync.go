package model

import "time"

// SyncRequest is sent by the mobile client to push local changes
// and request remote changes since its last sync.
type SyncRequest struct {
	LastSyncedAt       *time.Time        `json:"last_synced_at"`
	Profiles           []Profile         `json:"profiles,omitempty"`
	CalorieItems       []CalorieItem     `json:"calorie_items,omitempty"`
	Products           []Product         `json:"products,omitempty"`
	ProductCategories  []ProductCategory `json:"product_categories,omitempty"`
	WakingPeriods      []WakingPeriod    `json:"waking_periods,omitempty"`
}

// SyncResponse contains remote changes the client should apply locally.
type SyncResponse struct {
	SyncedAt           time.Time         `json:"synced_at"`
	Profiles           []Profile         `json:"profiles,omitempty"`
	CalorieItems       []CalorieItem     `json:"calorie_items,omitempty"`
	Products           []Product         `json:"products,omitempty"`
	ProductCategories  []ProductCategory `json:"product_categories,omitempty"`
	WakingPeriods      []WakingPeriod    `json:"waking_periods,omitempty"`
}
