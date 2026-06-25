package services

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"

	"github.com/silk-tree/wuxu-app/internal/models"
	"github.com/silk-tree/wuxu-app/internal/mocks"
)

func TestItemService_Create_Success(t *testing.T) {
	mockItemRepo := mocks.NewMockItemRepository()
	mockPurchaseRepo := mocks.NewMockPurchaseRepository()
	service := NewItemService(mockItemRepo, mockPurchaseRepo)

	deviceID := "test-device-001"
	categoryID := uuid.New()
	expiryDate := time.Now().AddDate(0, 0, 10)

	item := &models.Item{
		Name:       "测试物品",
		CategoryID: categoryID,
		Quantity:   1,
		ExpiryDate: expiryDate,
	}

	mockPurchaseRepo.On("CountByDeviceID", deviceID).Return(int64(1), nil)
	mockItemRepo.On("Create", mock.Anything).Return(nil)

	result, err := service.Create(deviceID, item)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, "测试物品", result.Name)
	assert.Equal(t, deviceID, result.DeviceID)
	assert.Equal(t, models.StatusSafe, result.Status)

	mockPurchaseRepo.AssertExpectations(t)
	mockItemRepo.AssertExpectations(t)
}

func TestItemService_Create_LimitExceeded(t *testing.T) {
	mockItemRepo := mocks.NewMockItemRepository()
	mockPurchaseRepo := mocks.NewMockPurchaseRepository()
	service := NewItemService(mockItemRepo, mockPurchaseRepo)

	deviceID := "test-device-002"
	categoryID := uuid.New()
	expiryDate := time.Now().AddDate(0, 0, 10)

	item := &models.Item{
		Name:       "测试物品",
		CategoryID: categoryID,
		Quantity:   1,
		ExpiryDate: expiryDate,
	}

	mockPurchaseRepo.On("CountByDeviceID", deviceID).Return(int64(0), nil)
	mockItemRepo.On("CountByDeviceID", deviceID).Return(int64(20), nil)

	result, err := service.Create(deviceID, item)

	assert.Error(t, err)
	assert.Equal(t, ErrLimitExceeded, err)
	assert.Nil(t, result)

	mockPurchaseRepo.AssertExpectations(t)
	mockItemRepo.AssertExpectations(t)
}

func TestItemService_GetByID_Success(t *testing.T) {
	mockItemRepo := mocks.NewMockItemRepository()
	mockPurchaseRepo := mocks.NewMockPurchaseRepository()
	service := NewItemService(mockItemRepo, mockPurchaseRepo)

	itemID := uuid.New().String()
	expectedItem := &models.Item{
		Name: "测试物品",
	}

	mockItemRepo.On("GetByID", itemID).Return(expectedItem, nil)

	result, err := service.GetByID(itemID)

	assert.NoError(t, err)
	assert.Equal(t, expectedItem, result)

	mockItemRepo.AssertExpectations(t)
}

func TestItemService_GetByID_NotFound(t *testing.T) {
	mockItemRepo := mocks.NewMockItemRepository()
	mockPurchaseRepo := mocks.NewMockPurchaseRepository()
	service := NewItemService(mockItemRepo, mockPurchaseRepo)

	itemID := uuid.New().String()

	mockItemRepo.On("GetByID", itemID).Return(nil, errors.New("not found"))

	result, err := service.GetByID(itemID)

	assert.Error(t, err)
	assert.Nil(t, result)

	mockItemRepo.AssertExpectations(t)
}

func TestItemService_Delete_Success(t *testing.T) {
	mockItemRepo := mocks.NewMockItemRepository()
	mockPurchaseRepo := mocks.NewMockPurchaseRepository()
	service := NewItemService(mockItemRepo, mockPurchaseRepo)

	itemID := uuid.New().String()

	mockItemRepo.On("Delete", itemID).Return(nil)

	err := service.Delete(itemID)

	assert.NoError(t, err)

	mockItemRepo.AssertExpectations(t)
}

func TestItemService_List_Success(t *testing.T) {
	mockItemRepo := mocks.NewMockItemRepository()
	mockPurchaseRepo := mocks.NewMockPurchaseRepository()
	service := NewItemService(mockItemRepo, mockPurchaseRepo)

	deviceID := "test-device-001"
	items := []models.Item{
		{Name: "物品1"},
		{Name: "物品2"},
	}

	mockItemRepo.On("List", mock.Anything).Return(items, int64(2), nil)

	result, err := service.List(deviceID, "", "", "expiry_asc", 50, 0)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, int64(2), result.Total)
	assert.Len(t, result.Items, 2)

	mockItemRepo.AssertExpectations(t)
}

func TestCalculateStatus(t *testing.T) {
	tests := []struct {
		name     string
		days     int
		expected string
	}{
		{"过期", -1, models.StatusExpired},
		{"今天过期", 0, models.StatusWarning},
		{"3天后过期", 3, models.StatusWarning},
		{"7天后过期", 7, models.StatusWarning},
		{"8天后过期", 8, models.StatusSafe},
		{"30天后过期", 30, models.StatusSafe},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			expiryDate := time.Now().AddDate(0, 0, tt.days)
			status := models.CalculateStatus(expiryDate)
			assert.Equal(t, tt.expected, status)
		})
	}
}