package sqlite

import (
	"time"

	"cat-calories-server/internal/model"

	"github.com/jmoiron/sqlx"
)

type ProductCategoryRepo struct{ DB *sqlx.DB }

func (r *ProductCategoryRepo) Upsert(profileIDs []int64, c model.ProductCategory) error {
	if !isAllowed(profileIDs, c.ProfileID) {
		return nil
	}
	_, err := r.DB.Exec(`
		INSERT INTO product_categories (id, profile_id, name, icon_name, color_hex, sort_order, created_at, updated_at, deleted_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
			name=excluded.name, icon_name=excluded.icon_name, color_hex=excluded.color_hex,
			sort_order=excluded.sort_order, updated_at=excluded.updated_at, deleted_at=excluded.deleted_at
		WHERE excluded.updated_at >= product_categories.updated_at OR product_categories.updated_at IS NULL
	`, c.ID, c.ProfileID, c.Name, c.IconName, c.ColorHex, c.SortOrder, c.CreatedAt, c.UpdatedAt, c.DeletedAt)
	return err
}

func (r *ProductCategoryRepo) ChangedSince(profileIDs []int64, since time.Time) ([]model.ProductCategory, error) {
	if len(profileIDs) == 0 {
		return nil, nil
	}
	query, args, err := sqlx.In("SELECT * FROM product_categories WHERE profile_id IN (?) AND updated_at > ?", profileIDs, since)
	if err != nil {
		return nil, err
	}
	var out []model.ProductCategory
	err = r.DB.Select(&out, r.DB.Rebind(query), args...)
	return out, err
}
