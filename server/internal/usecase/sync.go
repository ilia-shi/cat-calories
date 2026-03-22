package usecase

import (
	"fmt"
	"time"

	"cat-calories-server/internal/model"
	"cat-calories-server/internal/repository"
)

type SyncUseCase struct {
	Profiles          repository.ProfileRepository
	CalorieItems      repository.CalorieItemRepository
	Products          repository.ProductRepository
	ProductCategories repository.ProductCategoryRepository
	WakingPeriods     repository.WakingPeriodRepository
}

func (uc *SyncUseCase) Process(userID string, req model.SyncRequest) (*model.SyncResponse, error) {
	now := time.Now().UTC()

	profileIDs, err := uc.Profiles.FindByUser(userID)
	if err != nil {
		return nil, err
	}

	// Upsert incoming data from client
	for i, p := range req.Profiles {
		if err := uc.Profiles.Upsert(userID, p); err != nil {
			return nil, fmt.Errorf("profile[%d] id=%d: %w", i, p.ID, err)
		}
	}

	// Refresh profile IDs after upserting profiles so new ones are included
	profileIDs, err = uc.Profiles.FindByUser(userID)
	if err != nil {
		return nil, err
	}

	// Upsert waking periods and products before calorie items (foreign keys)
	for i, wp := range req.WakingPeriods {
		if err := uc.WakingPeriods.Upsert(profileIDs, wp); err != nil {
			return nil, fmt.Errorf("waking_period[%d] id=%d profile_id=%d: %w", i, wp.ID, wp.ProfileID, err)
		}
	}
	for i, c := range req.ProductCategories {
		if err := uc.ProductCategories.Upsert(profileIDs, c); err != nil {
			return nil, fmt.Errorf("product_category[%d] id=%s profile_id=%d: %w", i, c.ID, c.ProfileID, err)
		}
	}
	for i, p := range req.Products {
		if err := uc.Products.Upsert(profileIDs, p); err != nil {
			return nil, fmt.Errorf("product[%d] id=%s profile_id=%d: %w", i, p.ID, p.ProfileID, err)
		}
	}
	// Collect valid waking period IDs to avoid FK constraint failures
	wpIDs, err := uc.WakingPeriods.FindIDsByProfiles(profileIDs)
	if err != nil {
		return nil, fmt.Errorf("find waking period IDs: %w", err)
	}
	validWP := map[int64]bool{}
	for _, id := range wpIDs {
		validWP[id] = true
	}
	for i, item := range req.CalorieItems {
		if item.WakingPeriodID != nil && !validWP[*item.WakingPeriodID] {
			req.CalorieItems[i].WakingPeriodID = nil
			item = req.CalorieItems[i]
		}
		if err := uc.CalorieItems.Upsert(profileIDs, item); err != nil {
			return nil, fmt.Errorf("calorie_item[%d] id=%s profile_id=%d waking_period_id=%v: %w", i, item.ID, item.ProfileID, item.WakingPeriodID, err)
		}
	}

	// Refresh profile IDs in case new ones were created
	profileIDs, err = uc.Profiles.FindByUser(userID)
	if err != nil {
		return nil, err
	}

	since := time.Time{}
	if req.LastSyncedAt != nil {
		since = *req.LastSyncedAt
	}

	resp := &model.SyncResponse{SyncedAt: now}

	resp.Profiles, err = uc.Profiles.ChangedSince(userID, since)
	if err != nil {
		return nil, err
	}
	resp.CalorieItems, err = uc.CalorieItems.ChangedSince(profileIDs, since)
	if err != nil {
		return nil, err
	}
	resp.Products, err = uc.Products.ChangedSince(profileIDs, since)
	if err != nil {
		return nil, err
	}
	resp.ProductCategories, err = uc.ProductCategories.ChangedSince(profileIDs, since)
	if err != nil {
		return nil, err
	}
	resp.WakingPeriods, err = uc.WakingPeriods.ChangedSince(profileIDs, since)
	if err != nil {
		return nil, err
	}

	return resp, nil
}
