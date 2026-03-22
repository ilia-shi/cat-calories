package sqlite

import (
	"time"

	"cat-calories-server/internal/model"

	"github.com/jmoiron/sqlx"
)

type CalorieItemRepo struct{ DB *sqlx.DB }

func (r *CalorieItemRepo) Upsert(profileIDs []int64, item model.CalorieItem) error {
	if !isAllowed(profileIDs, item.ProfileID) {
		return nil
	}
	_, err := r.DB.Exec(`
		INSERT INTO calorie_items (id, profile_id, waking_period_id, product_id, value, description, sort_order,
			weight_grams, protein_grams, fat_grams, carb_grams, eaten_at, created_at, updated_at, deleted_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
			value=excluded.value, description=excluded.description, sort_order=excluded.sort_order,
			weight_grams=excluded.weight_grams, protein_grams=excluded.protein_grams,
			fat_grams=excluded.fat_grams, carb_grams=excluded.carb_grams,
			eaten_at=excluded.eaten_at, updated_at=excluded.updated_at, deleted_at=excluded.deleted_at
		WHERE excluded.updated_at >= calorie_items.updated_at OR calorie_items.updated_at IS NULL
	`, item.ID, item.ProfileID, item.WakingPeriodID, item.ProductID,
		item.Value, item.Description, item.SortOrder,
		item.WeightGrams, item.ProteinGrams, item.FatGrams, item.CarbGrams,
		item.EatenAt, item.CreatedAt, item.UpdatedAt, item.DeletedAt)
	return err
}

func (r *CalorieItemRepo) FindByID(id string) (*model.CalorieItem, error) {
	var item model.CalorieItem
	err := r.DB.Get(&item, "SELECT * FROM calorie_items WHERE id = ? AND deleted_at IS NULL", id)
	if err != nil {
		return nil, err
	}
	return &item, nil
}

func (r *CalorieItemRepo) FindAllByProfile(profileID int64) ([]model.CalorieItem, error) {
	var items []model.CalorieItem
	err := r.DB.Select(&items, "SELECT * FROM calorie_items WHERE profile_id = ? AND deleted_at IS NULL ORDER BY created_at DESC", profileID)
	return items, err
}

func (r *CalorieItemRepo) FindAllByProfiles(profileIDs []int64) ([]model.CalorieItem, error) {
	if len(profileIDs) == 0 {
		return nil, nil
	}
	query, args, err := sqlx.In("SELECT * FROM calorie_items WHERE profile_id IN (?) AND deleted_at IS NULL ORDER BY created_at DESC", profileIDs)
	if err != nil {
		return nil, err
	}
	var items []model.CalorieItem
	err = r.DB.Select(&items, r.DB.Rebind(query), args...)
	return items, err
}

func (r *CalorieItemRepo) Insert(item *model.CalorieItem) error {
	_, err := r.DB.Exec(`
		INSERT INTO calorie_items (id, profile_id, waking_period_id, product_id, value, description, sort_order,
			weight_grams, protein_grams, fat_grams, carb_grams, eaten_at, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, item.ID, item.ProfileID, item.WakingPeriodID, item.ProductID,
		item.Value, item.Description, item.SortOrder,
		item.WeightGrams, item.ProteinGrams, item.FatGrams, item.CarbGrams,
		item.EatenAt, item.CreatedAt, item.UpdatedAt)
	return err
}

func (r *CalorieItemRepo) Update(item *model.CalorieItem) error {
	_, err := r.DB.Exec(`
		UPDATE calorie_items SET value=?, description=?, weight_grams=?, protein_grams=?,
			fat_grams=?, carb_grams=?, eaten_at=?, created_at=?, updated_at=?
		WHERE id=? AND deleted_at IS NULL
	`, item.Value, item.Description, item.WeightGrams, item.ProteinGrams,
		item.FatGrams, item.CarbGrams, item.EatenAt, item.CreatedAt, item.UpdatedAt,
		item.ID)
	return err
}

func (r *CalorieItemRepo) SoftDelete(id string) error {
	_, err := r.DB.Exec("UPDATE calorie_items SET deleted_at = datetime('now'), updated_at = datetime('now') WHERE id = ?", id)
	return err
}

func (r *CalorieItemRepo) ChangedSince(profileIDs []int64, since time.Time) ([]model.CalorieItem, error) {
	if len(profileIDs) == 0 {
		return nil, nil
	}
	query, args, err := sqlx.In("SELECT * FROM calorie_items WHERE profile_id IN (?) AND updated_at > ?", profileIDs, since)
	if err != nil {
		return nil, err
	}
	var out []model.CalorieItem
	err = r.DB.Select(&out, r.DB.Rebind(query), args...)
	return out, err
}
