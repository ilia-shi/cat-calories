package repository

import (
	"encoding/json"
	"time"

	"cat-calories-server/internal/model"
)

type UserRepository interface {
	FindByID(id string) (*model.User, error)
	FindByProviderSubject(provider, subject string) (*model.User, error)
	FindByEmail(email string) (*model.User, error)
	Create(email, name, passwordHash, provider, subject string) (string, error)
}

type ProfileRepository interface {
	FindByUser(userID string) ([]int64, error)
	FindByID(id int64) (*model.Profile, error)
	Upsert(userID string, p model.Profile) error
	ChangedSince(userID string, since time.Time) ([]model.Profile, error)
}

type CalorieItemRepository interface {
	Upsert(profileIDs []int64, item model.CalorieItem) error
	ChangedSince(profileIDs []int64, since time.Time) ([]model.CalorieItem, error)
	FindByID(id string) (*model.CalorieItem, error)
	FindAllByProfile(profileID int64) ([]model.CalorieItem, error)
	FindAllByProfiles(profileIDs []int64) ([]model.CalorieItem, error)
	Insert(item *model.CalorieItem) error
	Update(item *model.CalorieItem) error
	SoftDelete(id string) error
}

type ProductRepository interface {
	Upsert(profileIDs []int64, p model.Product) error
	ChangedSince(profileIDs []int64, since time.Time) ([]model.Product, error)
}

type ProductCategoryRepository interface {
	Upsert(profileIDs []int64, c model.ProductCategory) error
	ChangedSince(profileIDs []int64, since time.Time) ([]model.ProductCategory, error)
}

type WakingPeriodRepository interface {
	Upsert(profileIDs []int64, wp model.WakingPeriod) error
	ChangedSince(profileIDs []int64, since time.Time) ([]model.WakingPeriod, error)
	FindActiveByProfile(profileID int64) (*model.WakingPeriod, error)
	FindIDsByProfiles(profileIDs []int64) ([]int64, error)
}

// SyncEntryRepository handles the v2 sync protocol storage.
type SyncEntryRepository interface {
	// Upsert stores or updates a sync entry. Returns true if accepted (new or newer version).
	Upsert(entry model.SyncEntry) (bool, error)

	// FindSince returns entries for a user+entityType where server_hlc > sinceHLC.
	FindSince(userID, entityType, sinceHLC string, limit int) ([]model.SyncEntry, error)

	// CheckIdempotency returns (accepted, found). If found, the push was already processed.
	CheckIdempotency(key, userID string) (int, bool, error)

	// SaveIdempotency records a completed push for deduplication.
	SaveIdempotency(key, userID string, accepted int) error

	// FindByEntityID returns a single sync entry for conflict detection.
	FindByEntityID(entityType, entityID string) (*model.SyncEntry, error)

	// ExtractScope reads the profile_id (scope) from a JSON payload.
	ExtractScope(payload json.RawMessage) string
}
