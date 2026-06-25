package repository

import (
	"gorm.io/gorm"

	"github.com/silk-tree/wuxu-app/internal/models"
)

type CategoryRepository interface {
	List() ([]models.Category, error)
	GetByValue(value string) (*models.Category, error)
	GetByID(id string) (*models.Category, error)
}

type categoryRepository struct {
	db *gorm.DB
}

func NewCategoryRepository(db *gorm.DB) CategoryRepository {
	return &categoryRepository{db: db}
}

func (r *categoryRepository) List() ([]models.Category, error) {
	var categories []models.Category
	err := r.db.Order("sort_order ASC").Find(&categories).Error
	return categories, err
}

func (r *categoryRepository) GetByValue(value string) (*models.Category, error) {
	var category models.Category
	err := r.db.Where("value = ?", value).First(&category).Error
	if err != nil {
		return nil, err
	}
	return &category, nil
}

func (r *categoryRepository) GetByID(id string) (*models.Category, error) {
	var category models.Category
	err := r.db.Where("id = ?", id).First(&category).Error
	if err != nil {
		return nil, err
	}
	return &category, nil
}
