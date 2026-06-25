package mocks

import (
	"github.com/stretchr/testify/mock"
	"github.com/silk-tree/wuxu-app/internal/models"
	"github.com/silk-tree/wuxu-app/internal/repository"
)

type MockItemRepository struct {
	mock.Mock
}

func NewMockItemRepository() *MockItemRepository {
	return &MockItemRepository{}
}

func (m *MockItemRepository) Create(item *models.Item) error {
	args := m.Called(item)
	return args.Error(0)
}

func (m *MockItemRepository) GetByID(id string) (*models.Item, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Item), args.Error(1)
}

func (m *MockItemRepository) Update(item *models.Item) error {
	args := m.Called(item)
	return args.Error(0)
}

func (m *MockItemRepository) Delete(id string) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockItemRepository) List(query repository.ItemListQuery) ([]models.Item, int64, error) {
	args := m.Called(query)
	return args.Get(0).([]models.Item), args.Get(1).(int64), args.Error(2)
}

func (m *MockItemRepository) CountByDeviceID(deviceID string) (int64, error) {
	args := m.Called(deviceID)
	return args.Get(0).(int64), args.Error(1)
}

type MockPurchaseRepository struct {
	mock.Mock
}

func NewMockPurchaseRepository() *MockPurchaseRepository {
	return &MockPurchaseRepository{}
}

func (m *MockPurchaseRepository) Create(purchase *models.Purchase) error {
	args := m.Called(purchase)
	return args.Error(0)
}

func (m *MockPurchaseRepository) GetByID(id string) (*models.Purchase, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Purchase), args.Error(1)
}

func (m *MockPurchaseRepository) ListByDeviceID(deviceID string) ([]models.Purchase, error) {
	args := m.Called(deviceID)
	return args.Get(0).([]models.Purchase), args.Error(1)
}

func (m *MockPurchaseRepository) CountByDeviceID(deviceID string) (int64, error) {
	args := m.Called(deviceID)
	return args.Get(0).(int64), args.Error(1)
}

type MockCategoryRepository struct {
	mock.Mock
}

func NewMockCategoryRepository() *MockCategoryRepository {
	return &MockCategoryRepository{}
}

func (m *MockCategoryRepository) Create(category *models.Category) error {
	args := m.Called(category)
	return args.Error(0)
}

func (m *MockCategoryRepository) List() ([]models.Category, error) {
	args := m.Called()
	return args.Get(0).([]models.Category), args.Error(1)
}

func (m *MockCategoryRepository) GetByID(id string) (*models.Category, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Category), args.Error(1)
}

func (m *MockCategoryRepository) GetByName(name string) (*models.Category, error) {
	args := m.Called(name)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.Category), args.Error(1)
}

func (m *MockCategoryRepository) Update(category *models.Category) error {
	args := m.Called(category)
	return args.Error(0)
}

func (m *MockCategoryRepository) Delete(id string) error {
	args := m.Called(id)
	return args.Error(0)
}