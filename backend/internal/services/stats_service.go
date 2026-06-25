package services

import (
	"github.com/silk-tree/wuxu-app/internal/models"
	"github.com/silk-tree/wuxu-app/internal/repository"
)

type StatsService interface {
	GetStats(deviceID string) (*StatsResult, error)
}

type StatsResult struct {
	TotalItems    int64 `json:"total_items"`
	ExpiredCount  int64 `json:"expired_count"`
	WarningCount  int64 `json:"warning_count"`
	SafeCount     int64 `json:"safe_count"`
	IsPremium     bool  `json:"is_premium"`
}

type statsService struct {
	itemRepo    repository.ItemRepository
	purchaseRepo repository.PurchaseRepository
}

func NewStatsService(itemRepo repository.ItemRepository, purchaseRepo repository.PurchaseRepository) StatsService {
	return &statsService{
		itemRepo:    itemRepo,
		purchaseRepo: purchaseRepo,
	}
}

func (s *statsService) GetStats(deviceID string) (*StatsResult, error) {
	isPremium, err := s.purchaseRepo.CountByDeviceID(deviceID)
	if err != nil {
		return nil, err
	}

	totalItems, err := s.itemRepo.CountByDeviceID(deviceID)
	if err != nil {
		return nil, err
	}

	expiredQuery := repository.ItemListQuery{
		DeviceID: deviceID,
		Status:   models.StatusExpired,
		Page:     1,
		PageSize: 1000,
	}
	_, expiredCount, err := s.itemRepo.List(expiredQuery)
	if err != nil {
		return nil, err
	}

	warningQuery := repository.ItemListQuery{
		DeviceID: deviceID,
		Status:   models.StatusWarning,
		Page:     1,
		PageSize: 1000,
	}
	_, warningCount, err := s.itemRepo.List(warningQuery)
	if err != nil {
		return nil, err
	}

	safeQuery := repository.ItemListQuery{
		DeviceID: deviceID,
		Status:   models.StatusSafe,
		Page:     1,
		PageSize: 1000,
	}
	_, safeCount, err := s.itemRepo.List(safeQuery)
	if err != nil {
		return nil, err
	}

	return &StatsResult{
		TotalItems:   totalItems,
		ExpiredCount: expiredCount,
		WarningCount: warningCount,
		SafeCount:    safeCount,
		IsPremium:    isPremium > 0,
	}, nil
}