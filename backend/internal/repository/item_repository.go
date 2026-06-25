package repository

import (
	"gorm.io/gorm"

	"github.com/silk-tree/wuxu-app/internal/models"
)

type ItemListQuery struct {
	DeviceID string
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
	CountByDeviceID(deviceID string) (int64, error)
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

	db := r.db.Model(&models.Item{}).Where("device_id = ?", query.DeviceID)

	if query.Category != "" {
		db = db.Where("category_id IN (SELECT id FROM categories WHERE name = ?)", query.Category)
	}

	if query.Status != "" && query.Status != "all" {
		db = db.Where("status = ?", query.Status)
	}

	db.Count(&total)

	sortField := "expiry_date"
	switch query.Sort {
	case "created_at":
		sortField = "created_at"
	case "name":
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

func (r *itemRepository) CountByDeviceID(deviceID string) (int64, error) {
	var count int64
	err := r.db.Model(&models.Item{}).Where("device_id = ?", deviceID).Count(&count).Error
	return count, err
}
