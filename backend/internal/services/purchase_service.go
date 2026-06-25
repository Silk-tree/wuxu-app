package services

import (
	"time"

	"github.com/silk-tree/wuxu-app/internal/models"
	"github.com/silk-tree/wuxu-app/internal/repository"
)

type PurchaseService interface {
	Create(deviceID string) (*models.Purchase, error)
	IsPremium(deviceID string) (bool, error)
}

type purchaseService struct {
	purchaseRepo repository.PurchaseRepository
}

func NewPurchaseService(purchaseRepo repository.PurchaseRepository) PurchaseService {
	return &purchaseService{purchaseRepo: purchaseRepo}
}

const PurchaseAmount = 100

func (s *purchaseService) Create(deviceID string) (*models.Purchase, error) {
	isPremium, err := s.IsPremium(deviceID)
	if err != nil {
		return nil, err
	}
	if isPremium {
		return nil, nil
	}

	purchase := &models.Purchase{
		DeviceID:    deviceID,
		PurchasedAt: time.Now(),
		Amount:      PurchaseAmount,
	}

	if err := s.purchaseRepo.Create(purchase); err != nil {
		return nil, err
	}

	return purchase, nil
}

func (s *purchaseService) IsPremium(deviceID string) (bool, error) {
	count, err := s.purchaseRepo.CountByDeviceID(deviceID)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}