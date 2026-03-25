package model

import (
	"encoding/json"
	"fmt"
	"sync"
	"time"
)

// SyncEntry stores a single versioned entity in the sync log.
// Maps to the sync_entries table and the SyncEntry protobuf message.
type SyncEntry struct {
	EntityType string          `db:"entity_type" json:"entity_type"`
	EntityID   string          `db:"entity_id"   json:"entity_id"`
	Scope      string          `db:"scope"        json:"scope,omitempty"` // profile_id
	UserID     string          `db:"user_id"      json:"-"`
	ClientHLC  string          `db:"client_hlc"   json:"hlc"`
	ServerHLC  string          `db:"server_hlc"   json:"-"`
	Version    int             `db:"version"      json:"version"`
	IsDeleted  bool            `db:"is_deleted"   json:"is_deleted"`
	Payload    json.RawMessage `db:"payload"      json:"payload,omitempty"`
	CreatedAt  time.Time       `db:"created_at"   json:"-"`
}

// PushRequest matches the Dart SyncBatch.
type PushRequest struct {
	IdempotencyKey string          `json:"idempotency_key"`
	EntityType     string          `json:"entity_type"`
	Entries        []PushSyncEntry `json:"entries"`
}

// PushSyncEntry is one entry in a push batch from the client.
type PushSyncEntry struct {
	EntityID  string          `json:"entity_id"`
	Version   int             `json:"version"`
	HLC       string          `json:"hlc"`
	IsDeleted bool            `json:"is_deleted"`
	Payload   json.RawMessage `json:"payload,omitempty"`
}

// PushResponse is returned to the client after a push.
type PushResponse struct {
	Accepted        int            `json:"accepted"`
	Rejected        int            `json:"rejected,omitempty"`
	Conflicts       []SyncConflict `json:"conflicts,omitempty"`
	ServerTimestamp *string        `json:"server_timestamp,omitempty"`
}

// SyncConflict describes a version conflict.
type SyncConflict struct {
	EntityID      string         `json:"entity_id"`
	LocalVersion  PushSyncEntry  `json:"local"`
	ServerVersion PullSyncEntry  `json:"server"`
}

// PullSyncEntry is one entry returned in a pull response.
type PullSyncEntry struct {
	EntityID  string          `json:"entity_id"`
	Version   int             `json:"version"`
	HLC       string          `json:"hlc"`
	IsDeleted bool            `json:"is_deleted"`
	Payload   json.RawMessage `json:"payload,omitempty"`
}

// PullResponse is returned to the client for a pull request.
type PullResponse struct {
	Entries         []PullSyncEntry `json:"entries"`
	HasMore         bool            `json:"has_more"`
	ServerTimestamp *string         `json:"server_timestamp,omitempty"`
}

// --- HLC Generator ---

// HLCGenerator produces monotonically increasing hybrid logical clock values.
// Format: "<unix_micros>-<counter>" — lexicographically sortable.
type HLCGenerator struct {
	mu      sync.Mutex
	lastTS  int64
	counter int
}

func NewHLCGenerator() *HLCGenerator {
	return &HLCGenerator{}
}

// Next returns the next HLC value, guaranteed to be greater than any previous value.
func (g *HLCGenerator) Next() string {
	g.mu.Lock()
	defer g.mu.Unlock()

	now := time.Now().UnixMicro()
	if now <= g.lastTS {
		g.counter++
	} else {
		g.lastTS = now
		g.counter = 0
	}

	return fmt.Sprintf("%019d-%04d", g.lastTS, g.counter)
}
