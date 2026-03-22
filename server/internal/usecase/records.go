package usecase

import (
	"database/sql"
	"errors"
	"fmt"
	"time"

	"cat-calories-server/internal/model"
	"cat-calories-server/internal/repository"

	"github.com/google/uuid"
)

type RecordsUseCase struct {
	Profiles      repository.ProfileRepository
	CalorieItems  repository.CalorieItemRepository
	WakingPeriods repository.WakingPeriodRepository
}

type RecordAPIView struct {
	ID           string   `json:"id"`
	Value        float64  `json:"value"`
	Description  *string  `json:"description"`
	CreatedAt    string   `json:"created_at"`
	EatenAt      *string  `json:"eaten_at"`
	WeightGrams  *float64 `json:"weight_grams"`
	ProteinGrams *float64 `json:"protein_grams"`
	FatGrams     *float64 `json:"fat_grams"`
	CarbGrams    *float64 `json:"carb_grams"`
}

type ProfileAPIView struct {
	Name              string  `json:"name"`
	CaloriesLimitGoal float64 `json:"calories_limit_goal"`
}

type RecentMealView struct {
	ID          string  `json:"id"`
	Value       float64 `json:"value"`
	Description *string `json:"description"`
	EatenAt     string  `json:"eaten_at"`
}

type PeriodSummaryView struct {
	Calories float64 `json:"calories"`
	Goal     float64 `json:"goal"`
}

type RecordsListResponse struct {
	Profile ProfileAPIView  `json:"profile"`
	Records []RecordAPIView `json:"records"`
}

type HomeDashboardResponse struct {
	Profile    ProfileAPIView     `json:"profile"`
	Rolling24h float64           `json:"rolling_24h"`
	Today      float64           `json:"today"`
	Yesterday  float64           `json:"yesterday"`
	Avg7Days   float64           `json:"avg_7_days"`
	Period     *PeriodSummaryView `json:"period"`
	RecentMeals []RecentMealView `json:"recent_meals"`
}

func toRecordView(item model.CalorieItem) RecordAPIView {
	v := RecordAPIView{
		ID:           item.ID,
		Value:        item.Value,
		CreatedAt:    item.CreatedAt.UTC().Format(time.RFC3339),
		WeightGrams:  item.WeightGrams,
		ProteinGrams: item.ProteinGrams,
		FatGrams:     item.FatGrams,
		CarbGrams:    item.CarbGrams,
	}
	if item.Description != "" {
		v.Description = &item.Description
	}
	eat := item.EatenAt.UTC().Format(time.RFC3339)
	if !item.EatenAt.IsZero() {
		v.EatenAt = &eat
	}
	return v
}

func (uc *RecordsUseCase) resolveProfileIDs(userID string) ([]int64, error) {
	ids, err := uc.Profiles.FindByUser(userID)
	if err != nil {
		return nil, err
	}
	if len(ids) == 0 {
		return nil, fmt.Errorf("no profile found for user")
	}
	return ids, nil
}

func (uc *RecordsUseCase) resolveProfile(userID string) (*model.Profile, error) {
	ids, err := uc.resolveProfileIDs(userID)
	if err != nil {
		return nil, err
	}
	return uc.Profiles.FindByID(ids[0])
}

func (uc *RecordsUseCase) List(userID string) (*RecordsListResponse, error) {
	profileIDs, err := uc.resolveProfileIDs(userID)
	if err != nil {
		return nil, err
	}

	profile, err := uc.Profiles.FindByID(profileIDs[0])
	if err != nil {
		return nil, err
	}

	items, err := uc.CalorieItems.FindAllByProfiles(profileIDs)
	if err != nil {
		return nil, err
	}

	records := make([]RecordAPIView, len(items))
	for i, item := range items {
		records[i] = toRecordView(item)
	}

	return &RecordsListResponse{
		Profile: ProfileAPIView{
			Name:              profile.Name,
			CaloriesLimitGoal: float64(profile.CaloriesLimitGoal),
		},
		Records: records,
	}, nil
}

func (uc *RecordsUseCase) Create(userID string, req model.CreateRecordRequest) (*RecordAPIView, error) {
	profile, err := uc.resolveProfile(userID)
	if err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	eatenAt := now
	if req.EatenAt != nil {
		eatenAt = *req.EatenAt
	}

	item := model.CalorieItem{
		ID:           uuid.New().String(),
		ProfileID:    profile.ID,
		Value:        req.Value,
		Description:  stringVal(req.Description),
		EatenAt:      eatenAt,
		CreatedAt:    now,
		UpdatedAt:    now,
		WeightGrams:  req.WeightGrams,
		ProteinGrams: req.ProteinGrams,
		FatGrams:     req.FatGrams,
		CarbGrams:    req.CarbGrams,
	}

	if err := uc.CalorieItems.Insert(&item); err != nil {
		return nil, err
	}

	v := toRecordView(item)
	return &v, nil
}

func (uc *RecordsUseCase) Update(userID string, id string, fields map[string]interface{}) (*RecordAPIView, error) {
	profileIDs, err := uc.resolveProfileIDs(userID)
	if err != nil {
		return nil, err
	}

	item, err := uc.CalorieItems.FindByID(id)
	if err != nil {
		return nil, err
	}
	if !containsID(profileIDs, item.ProfileID) {
		return nil, fmt.Errorf("not found")
	}

	if v, ok := fields["value"]; ok {
		item.Value = toFloat(v)
	}
	if v, ok := fields["description"]; ok {
		if v == nil {
			item.Description = ""
		} else {
			item.Description = fmt.Sprintf("%v", v)
		}
	}
	if v, ok := fields["eaten_at"]; ok {
		if v == nil {
			item.EatenAt = time.Time{}
		} else if s, ok := v.(string); ok {
			if t, err := time.Parse(time.RFC3339, s); err == nil {
				item.EatenAt = t
			}
		}
	}
	if v, ok := fields["created_at"]; ok {
		if s, ok := v.(string); ok {
			if t, err := time.Parse(time.RFC3339, s); err == nil {
				item.CreatedAt = t
			}
		}
	}
	if v, ok := fields["weight_grams"]; ok {
		item.WeightGrams = toFloatPtr(v)
	}
	if v, ok := fields["protein_grams"]; ok {
		item.ProteinGrams = toFloatPtr(v)
	}
	if v, ok := fields["fat_grams"]; ok {
		item.FatGrams = toFloatPtr(v)
	}
	if v, ok := fields["carb_grams"]; ok {
		item.CarbGrams = toFloatPtr(v)
	}
	item.UpdatedAt = time.Now().UTC()

	if err := uc.CalorieItems.Update(item); err != nil {
		return nil, err
	}

	v := toRecordView(*item)
	return &v, nil
}

func toFloat(v interface{}) float64 {
	switch n := v.(type) {
	case float64:
		return n
	case int:
		return float64(n)
	default:
		return 0
	}
}

func toFloatPtr(v interface{}) *float64 {
	if v == nil {
		return nil
	}
	f := toFloat(v)
	return &f
}

func (uc *RecordsUseCase) Delete(userID string, id string) error {
	profileIDs, err := uc.resolveProfileIDs(userID)
	if err != nil {
		return err
	}

	item, err := uc.CalorieItems.FindByID(id)
	if err != nil {
		return err
	}
	if !containsID(profileIDs, item.ProfileID) {
		return fmt.Errorf("not found")
	}

	return uc.CalorieItems.SoftDelete(id)
}

func containsID(ids []int64, id int64) bool {
	for _, v := range ids {
		if v == id {
			return true
		}
	}
	return false
}

func (uc *RecordsUseCase) HomeDashboard(userID string) (*HomeDashboardResponse, error) {
	profileIDs, err := uc.resolveProfileIDs(userID)
	if err != nil {
		return nil, err
	}

	profile, err := uc.Profiles.FindByID(profileIDs[0])
	if err != nil {
		return nil, err
	}

	items, err := uc.CalorieItems.FindAllByProfiles(profileIDs)
	if err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	twentyFourHoursAgo := now.Add(-24 * time.Hour)
	todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	yesterdayStart := todayStart.Add(-24 * time.Hour)
	sevenDaysAgo := todayStart.Add(-7 * 24 * time.Hour)

	var rolling24h, today, yesterday float64
	dailyTotals := map[string]float64{}
	var recentMeals []RecentMealView

	for _, item := range items {
		eatenAt := item.EatenAt
		if eatenAt.IsZero() {
			eatenAt = item.CreatedAt
		}

		if !eatenAt.Before(twentyFourHoursAgo) {
			rolling24h += item.Value
			desc := &item.Description
			if item.Description == "" {
				desc = nil
			}
			recentMeals = append(recentMeals, RecentMealView{
				ID:          item.ID,
				Value:       item.Value,
				Description: desc,
				EatenAt:     eatenAt.UTC().Format(time.RFC3339),
			})
		}

		if !eatenAt.Before(todayStart) {
			today += item.Value
		}

		if !eatenAt.Before(yesterdayStart) && eatenAt.Before(todayStart) {
			yesterday += item.Value
		}

		// Accumulate daily totals for 7-day average
		dayKey := time.Date(eatenAt.Year(), eatenAt.Month(), eatenAt.Day(), 0, 0, 0, 0, time.UTC).Format("2006-01-02")
		if !eatenAt.Before(sevenDaysAgo) && eatenAt.Before(todayStart) {
			dailyTotals[dayKey] += item.Value
		}
	}

	var avg7Days float64
	if len(dailyTotals) > 0 {
		var sum float64
		for _, v := range dailyTotals {
			sum += v
		}
		avg7Days = sum / float64(len(dailyTotals))
	}

	// Current waking period
	var periodView *PeriodSummaryView
	wp, err := uc.WakingPeriods.FindActiveByProfile(profile.ID)
	if err == nil && wp != nil {
		periodCalories := 0.0
		for _, item := range items {
			if item.WakingPeriodID != nil && *item.WakingPeriodID == wp.ID {
				periodCalories += item.Value
			}
		}
		periodView = &PeriodSummaryView{
			Calories: periodCalories,
			Goal:     float64(wp.CaloriesLimitGoal),
		}
	} else if err != nil && !errors.Is(err, sql.ErrNoRows) {
		return nil, err
	}

	if recentMeals == nil {
		recentMeals = []RecentMealView{}
	}

	return &HomeDashboardResponse{
		Profile: ProfileAPIView{
			Name:              profile.Name,
			CaloriesLimitGoal: float64(profile.CaloriesLimitGoal),
		},
		Rolling24h:  rolling24h,
		Today:       today,
		Yesterday:   yesterday,
		Avg7Days:    avg7Days,
		Period:      periodView,
		RecentMeals: recentMeals,
	}, nil
}

func stringVal(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}
