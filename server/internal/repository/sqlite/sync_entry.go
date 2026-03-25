package sqlite

import (
	"database/sql"
	"encoding/json"

	"cat-calories-server/internal/model"

	"github.com/jmoiron/sqlx"
)

type SyncEntryRepo struct {
	DB  *sqlx.DB
	HLC *model.HLCGenerator
}

func (r *SyncEntryRepo) Upsert(entry model.SyncEntry) (bool, error) {
	// Only accept if version is newer than what we have
	var existing model.SyncEntry
	err := r.DB.Get(&existing,
		`SELECT version, server_hlc FROM sync_entries WHERE entity_type = ? AND entity_id = ?`,
		entry.EntityType, entry.EntityID)

	if err == sql.ErrNoRows {
		// New entry — insert
		entry.ServerHLC = r.HLC.Next()
		_, err = r.DB.Exec(`
			INSERT INTO sync_entries (entity_type, entity_id, scope, user_id, client_hlc, server_hlc, version, is_deleted, payload)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
			entry.EntityType, entry.EntityID, entry.Scope, entry.UserID,
			entry.ClientHLC, entry.ServerHLC, entry.Version, entry.IsDeleted, entry.Payload)
		return err == nil, err
	}
	if err != nil {
		return false, err
	}

	// Existing entry — only update if client version is newer
	if entry.Version <= existing.Version {
		return false, nil // reject: server has same or newer version
	}

	entry.ServerHLC = r.HLC.Next()
	_, err = r.DB.Exec(`
		UPDATE sync_entries
		SET scope = ?, client_hlc = ?, server_hlc = ?, version = ?, is_deleted = ?, payload = ?
		WHERE entity_type = ? AND entity_id = ?`,
		entry.Scope, entry.ClientHLC, entry.ServerHLC, entry.Version, entry.IsDeleted, entry.Payload,
		entry.EntityType, entry.EntityID)
	return err == nil, err
}

func (r *SyncEntryRepo) FindSince(userID, entityType, sinceHLC string, limit int) ([]model.SyncEntry, error) {
	var entries []model.SyncEntry
	err := r.DB.Select(&entries, `
		SELECT entity_type, entity_id, scope, user_id, client_hlc, server_hlc, version, is_deleted, payload
		FROM sync_entries
		WHERE user_id = ? AND entity_type = ? AND server_hlc > ?
		ORDER BY server_hlc ASC
		LIMIT ?`,
		userID, entityType, sinceHLC, limit)
	if err != nil {
		return nil, err
	}
	if entries == nil {
		entries = []model.SyncEntry{}
	}
	return entries, nil
}

func (r *SyncEntryRepo) CheckIdempotency(key, userID string) (int, bool, error) {
	var accepted int
	err := r.DB.Get(&accepted,
		`SELECT accepted FROM sync_idempotency WHERE idempotency_key = ? AND user_id = ?`,
		key, userID)
	if err == sql.ErrNoRows {
		return 0, false, nil
	}
	if err != nil {
		return 0, false, err
	}
	return accepted, true, nil
}

func (r *SyncEntryRepo) SaveIdempotency(key, userID string, accepted int) error {
	_, err := r.DB.Exec(
		`INSERT OR IGNORE INTO sync_idempotency (idempotency_key, user_id, accepted) VALUES (?, ?, ?)`,
		key, userID, accepted)
	return err
}

func (r *SyncEntryRepo) FindByEntityID(entityType, entityID string) (*model.SyncEntry, error) {
	var entry model.SyncEntry
	err := r.DB.Get(&entry,
		`SELECT entity_type, entity_id, scope, user_id, client_hlc, server_hlc, version, is_deleted, payload
		 FROM sync_entries WHERE entity_type = ? AND entity_id = ?`,
		entityType, entityID)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &entry, nil
}

func (r *SyncEntryRepo) ExtractScope(payload json.RawMessage) string {
	if payload == nil {
		return ""
	}
	var m map[string]interface{}
	if err := json.Unmarshal(payload, &m); err != nil {
		return ""
	}
	if v, ok := m["profile_id"]; ok {
		switch s := v.(type) {
		case string:
			return s
		case float64:
			return json.Number(json.Number(string(rune(int(s))))).String()
		}
	}
	return ""
}
