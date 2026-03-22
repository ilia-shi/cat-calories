package sqlite

import (
	"time"

	"cat-calories-server/internal/model"

	"github.com/jmoiron/sqlx"
)

type ProductRepo struct{ DB *sqlx.DB }

func (r *ProductRepo) Upsert(profileIDs []int64, p model.Product) error {
	if !isAllowed(profileIDs, p.ProfileID) {
		return nil
	}
	_, err := r.DB.Exec(`
		INSERT INTO products (id, profile_id, category_id, title, description, barcode,
			calories_per_100g, proteins_per_100g, fats_per_100g, carbs_per_100g,
			package_weight_g, uses_count, last_used_at, sort_order, created_at, updated_at, deleted_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
			title=excluded.title, description=excluded.description, barcode=excluded.barcode,
			calories_per_100g=excluded.calories_per_100g, proteins_per_100g=excluded.proteins_per_100g,
			fats_per_100g=excluded.fats_per_100g, carbs_per_100g=excluded.carbs_per_100g,
			package_weight_g=excluded.package_weight_g, uses_count=excluded.uses_count,
			last_used_at=excluded.last_used_at, sort_order=excluded.sort_order,
			updated_at=excluded.updated_at, deleted_at=excluded.deleted_at
		WHERE excluded.updated_at >= products.updated_at OR products.updated_at IS NULL
	`, p.ID, p.ProfileID, p.CategoryID, p.Title, p.Description, p.Barcode,
		p.CaloriesPer100g, p.ProteinsPer100g, p.FatsPer100g, p.CarbsPer100g,
		p.PackageWeightG, p.UsesCount, p.LastUsedAt, p.SortOrder,
		p.CreatedAt, p.UpdatedAt, p.DeletedAt)
	return err
}

func (r *ProductRepo) ChangedSince(profileIDs []int64, since time.Time) ([]model.Product, error) {
	if len(profileIDs) == 0 {
		return nil, nil
	}
	query, args, err := sqlx.In("SELECT * FROM products WHERE profile_id IN (?) AND updated_at > ?", profileIDs, since)
	if err != nil {
		return nil, err
	}
	var out []model.Product
	err = r.DB.Select(&out, r.DB.Rebind(query), args...)
	return out, err
}
