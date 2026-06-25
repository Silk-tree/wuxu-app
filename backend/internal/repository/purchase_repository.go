package repository

import (
	"gorm.io/gorm"

	"github.com/silk-tree/wuxu-app/internal/models"
)

type PurchaseRepository interface {
	Create(purchase *models.Purchase) error
	GetByID(id string) (*models.Purchase, error)
	ListByDeviceID(deviceID string) ([]models.Purchase, error)
	CountByDeviceID(deviceID string) (int64, error)
}

type purchaseRepository struct {
	db *gorm.DB
}

func NewPurchaseRepository(db *gorm.DB) PurchaseRepository {
	return &purchaseRepository{db: db}
}

func (r *purchaseRepository) Create(purchase *models.Purchase) error {
	return r.db.Create(purchase).Error
}

func (r *purchaseRepository) GetByID(id string) (*models.Purchase, error) {
	var purchase models.Purchase
	err := r.db.Where("id = ?", id).First(&purchase).Error
	if err != nil {
		return nil, err
	}
	return &purchase, nil
}

func (r *purchaseRepository) ListByDeviceID(deviceID string) ([]models.Purchase, error) {
	var purchases []models.Purchase
	err := r.db.Where("device_id = ?", deviceID).
		Order("purchased_at DESC").
		Find(&purchases).Error
	return purchases, err
}

func (r *purchaseRepository) CountByDeviceID(deviceID string) (int64, error) {
	var count int64
	err := r.db.Model(&models.Purchase{}).
		Where("device_id = ?", deviceID).
		Count(&count).Error
	return count, err
}
