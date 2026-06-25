package repository

import (
	"gorm.io/gorm"

	"github.com/silk-tree/wuxu-app/internal/models"
)

type CategoryRepository interface {
	Create(category *models.Category) error
	List() ([]models.Category, error)
	GetByID(id string) (*models.Category, error)
	GetByName(name string) (*models.Category, error)
	Update(category *models.Category) error
	Delete(id string) error
}

type categoryRepository struct {
	db *gorm.DB
}

func NewCategoryRepository(db *gorm.DB) CategoryRepository {
	return &categoryRepository{db: db}
}

func (r *categoryRepository) Create(category *models.Category) error {
	return r.db.Create(category).Error
}

func (r *categoryRepository) List() ([]models.Category, error) {
	var categories []models.Category
	err := r.db.Order("sort_order ASC").Find(&categories).Error
	return categories, err
}

func (r *categoryRepository) GetByID(id string) (*models.Category, error) {
	var category models.Category
	err := r.db.Where("id = ?", id).First(&category).Error
	if err != nil {
		return nil, err
	}
	return &category, nil
}

func (r *categoryRepository) GetByName(name string) (*models.Category, error) {
	var category models.Category
	err := r.db.Where("name = ?", name).First(&category).Error
	if err != nil {
		return nil, err
	}
	return &category, nil
}

func (r *categoryRepository) Update(category *models.Category) error {
	return r.db.Save(category).Error
}

func (r *categoryRepository) Delete(id string) error {
	return r.db.Delete(&models.Category{}, "id = ?", id).Error
}
