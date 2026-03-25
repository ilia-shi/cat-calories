package usecase

import (
	"fmt"
	"log"

	"cat-calories-server/internal/model"
	"cat-calories-server/internal/repository"
)

// SyncV2UseCase handles the new entity-based sync protocol.
// Currently supports: calorie_item.
type SyncV2UseCase struct {
	SyncEntries repository.SyncEntryRepository
}

// AllowedEntityTypes lists entity types that the sync v2 protocol accepts.
var AllowedEntityTypes = map[string]bool{
	"calorie_item": true,
}

// Push processes a batch of incoming sync entries from a client.
func (uc *SyncV2UseCase) Push(userID string, req model.PushRequest) (*model.PushResponse, error) {
	if !AllowedEntityTypes[req.EntityType] {
		return nil, fmt.Errorf("unsupported entity type: %s", req.EntityType)
	}

	// Idempotency check
	if req.IdempotencyKey != "" {
		accepted, found, err := uc.SyncEntries.CheckIdempotency(req.IdempotencyKey, userID)
		if err != nil {
			return nil, fmt.Errorf("idempotency check: %w", err)
		}
		if found {
			return &model.PushResponse{Accepted: accepted}, nil
		}
	}

	accepted := 0
	rejected := 0
	var conflicts []model.SyncConflict

	for _, entry := range req.Entries {
		scope := uc.SyncEntries.ExtractScope(entry.Payload)

		syncEntry := model.SyncEntry{
			EntityType: req.EntityType,
			EntityID:   entry.EntityID,
			Scope:      scope,
			UserID:     userID,
			ClientHLC:  entry.HLC,
			Version:    entry.Version,
			IsDeleted:  entry.IsDeleted,
			Payload:    entry.Payload,
		}

		ok, err := uc.SyncEntries.Upsert(syncEntry)
		if err != nil {
			log.Printf("sync_v2: push error for entity %s/%s: %v", req.EntityType, entry.EntityID, err)
			rejected++
			continue
		}

		if ok {
			accepted++
		} else {
			// Version conflict — return the server's version
			existing, err := uc.SyncEntries.FindByEntityID(req.EntityType, entry.EntityID)
			if err == nil && existing != nil {
				conflicts = append(conflicts, model.SyncConflict{
					EntityID:     entry.EntityID,
					LocalVersion: entry,
					ServerVersion: model.PullSyncEntry{
						EntityID:  existing.EntityID,
						Version:   existing.Version,
						HLC:       existing.ClientHLC,
						IsDeleted: existing.IsDeleted,
						Payload:   existing.Payload,
					},
				})
			}
			rejected++
		}
	}

	// Save idempotency record
	if req.IdempotencyKey != "" {
		if err := uc.SyncEntries.SaveIdempotency(req.IdempotencyKey, userID, accepted); err != nil {
			log.Printf("sync_v2: idempotency save error: %v", err)
		}
	}

	resp := &model.PushResponse{
		Accepted:  accepted,
		Rejected:  rejected,
		Conflicts: conflicts,
	}

	return resp, nil
}

// Pull returns sync entries changed since the given HLC for a user+entityType.
func (uc *SyncV2UseCase) Pull(userID, entityType, sinceHLC string, limit int) (*model.PullResponse, error) {
	if !AllowedEntityTypes[entityType] {
		return nil, fmt.Errorf("unsupported entity type: %s", entityType)
	}

	if limit <= 0 || limit > 1000 {
		limit = 100
	}

	entries, err := uc.SyncEntries.FindSince(userID, entityType, sinceHLC, limit+1)
	if err != nil {
		return nil, err
	}

	hasMore := len(entries) > limit
	if hasMore {
		entries = entries[:limit]
	}

	pullEntries := make([]model.PullSyncEntry, len(entries))
	var lastHLC string
	for i, e := range entries {
		pullEntries[i] = model.PullSyncEntry{
			EntityID:  e.EntityID,
			Version:   e.Version,
			HLC:       e.ClientHLC,
			IsDeleted: e.IsDeleted,
			Payload:   e.Payload,
		}
		lastHLC = e.ServerHLC
	}

	resp := &model.PullResponse{
		Entries: pullEntries,
		HasMore: hasMore,
	}
	if lastHLC != "" {
		resp.ServerTimestamp = &lastHLC
	}

	return resp, nil
}
