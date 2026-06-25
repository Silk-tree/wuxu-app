package repository

import (
	"time"

	"gorm.io/gorm"

	"github.com/silk-tree/wuxu-app/internal/models"
)

type ItemListQuery struct {
	UserID   string
	Category string
	Status   string
	Sort     string
	Order    string
	Page     int
	PageSize int
}

type ItemRepository interface {
	Create(item *models.Item) error
	GetByID(id string) (*models.Item, error)
	Update(item *models.Item) error
	Delete(id string) error
	List(query ItemListQuery) ([]models.Item, int64, error)
	CountByUserID(userID string) (int64, error)
}

type itemRepository struct {
	db *gorm.DB
}

func NewItemRepository(db *gorm.DB) ItemRepository {
	return &itemRepository{db: db}
}

func (r *itemRepository) Create(item *models.Item) error {
	return r.db.Create(item).Error
}

func (r *itemRepository) GetByID(id string) (*models.Item, error) {
	var item models.Item
	err := r.db.Where("id = ?", id).First(&item).Error
	if err != nil {
		return nil, err
	}
	return &item, nil
}

func (r *itemRepository) Update(item *models.Item) error {
	return r.db.Save(item).Error
}

func (r *itemRepository) Delete(id string) error {
	return r.db.Delete(&models.Item{}, "id = ?", id).Error
}

func (r *itemRepository) List(query ItemListQuery) ([]models.Item, int64, error) {
	var items []models.Item
	var total int64

	db := r.db.Model(&models.Item{}).Where("user_id = ?", query.UserID)

	if query.Category != "" {
		db = db.Where("category_id IN (SELECT id FROM categories WHERE value = ?)", query.Category)
	}

	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())

	switch query.Status {
	case "expired":
		db = db.Where("expiry_date < ?", today)
	case "expiring":
		db = db.Where("expiry_date >= ? AND expiry_date <= ?", today, today.AddDate(0, 0, 7))
	case "safe":
		db = db.Where("expiry_date > ?", today.AddDate(0, 0, 7))
	}

	db.Count(&total)

	sortField := "expiry_date"
	if query.Sort == "created_at" {
		sortField = "created_at"
	} else if query.Sort == "name" {
		sortField = "name"
	}

	order := "ASC"
	if query.Order == "desc" {
		order = "DESC"
	}

	offset := (query.Page - 1) * query.PageSize
	if offset < 0 {
		offset = 0
	}
	if query.PageSize <= 0 {
		query.PageSize = 20
	}

	err := db.Order(sortField + " " + order).
		Preload("Category").
		Offset(offset).
		Limit(query.PageSize).
		Find(&items).Error

	return items, total, err
}

func (r *itemRepository) CountByUserID(userID string) (int64, error) {
	var count int64
	err := r.db.Model(&models.Item{}).Where("user_id = ?", userID).Count(&count).Error
	return count, err
}
