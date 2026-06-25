package services

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"

	"github.com/silk-tree/wuxu-app/internal/mocks"
)

func TestPurchaseService_Create_Success(t *testing.T) {
	mockPurchaseRepo := mocks.NewMockPurchaseRepository()
	service := NewPurchaseService(mockPurchaseRepo)

	deviceID := "test-device-001"

	mockPurchaseRepo.On("CountByDeviceID", deviceID).Return(int64(0), nil)
	mockPurchaseRepo.On("Create", mock.Anything).Return(nil)

	result, err := service.Create(deviceID)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, deviceID, result.DeviceID)
	assert.Equal(t, PurchaseAmount, result.Amount)

	mockPurchaseRepo.AssertExpectations(t)
}

func TestPurchaseService_Create_AlreadyPremium(t *testing.T) {
	mockPurchaseRepo := mocks.NewMockPurchaseRepository()
	service := NewPurchaseService(mockPurchaseRepo)

	deviceID := "test-device-002"

	mockPurchaseRepo.On("CountByDeviceID", deviceID).Return(int64(1), nil)

	result, err := service.Create(deviceID)

	assert.NoError(t, err)
	assert.Nil(t, result)

	mockPurchaseRepo.AssertExpectations(t)
}

func TestPurchaseService_IsPremium_True(t *testing.T) {
	mockPurchaseRepo := mocks.NewMockPurchaseRepository()
	service := NewPurchaseService(mockPurchaseRepo)

	deviceID := "test-device-003"

	mockPurchaseRepo.On("CountByDeviceID", deviceID).Return(int64(1), nil)

	isPremium, err := service.IsPremium(deviceID)

	assert.NoError(t, err)
	assert.True(t, isPremium)

	mockPurchaseRepo.AssertExpectations(t)
}

func TestPurchaseService_IsPremium_False(t *testing.T) {
	mockPurchaseRepo := mocks.NewMockPurchaseRepository()
	service := NewPurchaseService(mockPurchaseRepo)

	deviceID := "test-device-004"

	mockPurchaseRepo.On("CountByDeviceID", deviceID).Return(int64(0), nil)

	isPremium, err := service.IsPremium(deviceID)

	assert.NoError(t, err)
	assert.False(t, isPremium)

	mockPurchaseRepo.AssertExpectations(t)
}