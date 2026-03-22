package model

import "time"

type CreateRecordRequest struct {
	Value        float64    `json:"value"`
	Description  *string    `json:"description"`
	EatenAt      *time.Time `json:"eaten_at"`
	WeightGrams  *float64   `json:"weight_grams"`
	ProteinGrams *float64   `json:"protein_grams"`
	FatGrams     *float64   `json:"fat_grams"`
	CarbGrams    *float64   `json:"carb_grams"`
}
