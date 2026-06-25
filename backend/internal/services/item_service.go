package services

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/silk-tree/wuxu-app/internal/models"
	"github.com/silk-tree/wuxu-app/internal/repository"
)

const FreeItemLimit = 20

var ErrLimitExceeded = errors.New("免费用户物品数量已达上限")

type ItemService interface {
	Create(deviceID string, item *models.Item) (*models.Item, error)
	GetByID(id string) (*models.Item, error)
	List(deviceID string, status, categoryID, sort string, limit, offset int) (*ItemListResult, error)
	Update(id string, item *models.Item) (*models.Item, error)
	Delete(id string) error
}

type ItemListResult struct {
	Items  []models.Item `json:"items"`
	Total  int64         `json:"total"`
	Limit  int           `json:"limit"`
	Offset int           `json:"offset"`
}

type itemService struct {
	itemRepo    repository.ItemRepository
	purchaseRepo repository.PurchaseRepository
}

func NewItemService(itemRepo repository.ItemRepository, purchaseRepo repository.PurchaseRepository) ItemService {
	return &itemService{
		itemRepo:    itemRepo,
		purchaseRepo: purchaseRepo,
	}
}

func (s *itemService) isPremium(deviceID string) (bool, error) {
	count, err := s.purchaseRepo.CountByDeviceID(deviceID)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (s *itemService) Create(deviceID string, item *models.Item) (*models.Item, error) {
	isPremium, err := s.isPremium(deviceID)
	if err != nil {
		return nil, err
	}

	if !isPremium {
		count, err := s.itemRepo.CountByDeviceID(deviceID)
		if err != nil {
			return nil, err
		}
		if count >= FreeItemLimit {
			return nil, ErrLimitExceeded
		}
	}

	item.DeviceID = deviceID
	item.Status = models.CalculateStatus(item.ExpiryDate)

	if err := s.itemRepo.Create(item); err != nil {
		return nil, err
	}

	return item, nil
}

func (s *itemService) GetByID(id string) (*models.Item, error) {
	return s.itemRepo.GetByID(id)
}

func (s *itemService) List(deviceID string, status, categoryID, sort string, limit, offset int) (*ItemListResult, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}
	if offset < 0 {
		offset = 0
	}

	sortField := "expiry_date"
	order := "ASC"
	switch sort {
	case "expiry_desc":
		order = "DESC"
	case "created_desc":
		sortField = "created_at"
		order = "DESC"
	}

	query := repository.ItemListQuery{
		DeviceID: deviceID,
		Status:   status,
		Category: categoryID,
		Sort:     sortField,
		Order:    order,
		Page:     offset/limit + 1,
		PageSize: limit,
	}

	items, total, err := s.itemRepo.List(query)
	if err != nil {
		return nil, err
	}

	return &ItemListResult{
		Items:  items,
		Total:  total,
		Limit:  limit,
		Offset: offset,
	}, nil
}

func (s *itemService) Update(id string, item *models.Item) (*models.Item, error) {
	existing, err := s.itemRepo.GetByID(id)
	if err != nil {
		return nil, err
	}

	existing.Name = item.Name
	existing.CategoryID = item.CategoryID
	existing.Quantity = item.Quantity
	existing.Unit = item.Unit
	existing.ExpiryDate = item.ExpiryDate
	existing.StorageLocation = item.StorageLocation
	existing.Notes = item.Notes
	existing.Status = models.CalculateStatus(item.ExpiryDate)

	if err := s.itemRepo.Update(existing); err != nil {
		return nil, err
	}

	return existing, nil
}

func (s *itemService) Delete(id string) error {
	return s.itemRepo.Delete(id)
}

func ParseExpiryDate(dateStr string) (time.Time, error) {
	return time.Parse("2006-01-02", dateStr)
}

func ParseUUID(idStr string) (uuid.UUID, error) {
	return uuid.Parse(idStr)
}