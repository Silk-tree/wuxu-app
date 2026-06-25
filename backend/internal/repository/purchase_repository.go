package repository

import (
	"gorm.io/gorm"

	"github.com/silk-tree/wuxu-app/internal/models"
)

type PurchaseRepository interface {
	Create(purchase *models.Purchase) error
	GetByTransactionID(transactionID string) (*models.Purchase, error)
	ListByUserID(userID string) ([]models.Purchase, error)
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

func (r *purchaseRepository) GetByTransactionID(transactionID string) (*models.Purchase, error) {
	var purchase models.Purchase
	err := r.db.Where("transaction_id = ?", transactionID).First(&purchase).Error
	if err != nil {
		return nil, err
	}
	return &purchase, nil
}

func (r *purchaseRepository) ListByUserID(userID string) ([]models.Purchase, error) {
	var purchases []models.Purchase
	err := r.db.Where("user_id = ?", userID).Order("paid_at DESC").Find(&purchases).Error
	return purchases, err
}
