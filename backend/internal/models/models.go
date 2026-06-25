package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type BaseModel struct {
	ID        uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

func (m *BaseModel) BeforeCreate(tx *gorm.DB) error {
	if m.ID == uuid.Nil {
		m.ID = uuid.New()
	}
	return nil
}

const (
	StatusSafe    = "safe"
	StatusWarning = "warning"
	StatusExpired = "expired"
)

type Category struct {
	BaseModel
	Name      string `gorm:"type:varchar(50);uniqueIndex;not null" json:"name"`
	Icon      string `gorm:"type:varchar(20);not null" json:"icon"`
	SortOrder int    `gorm:"default:0;not null" json:"sort_order"`
}

func (Category) TableName() string {
	return "categories"
}

type Item struct {
	BaseModel
	Name            string    `gorm:"type:varchar(100);not null" json:"name"`
	CategoryID      uuid.UUID `gorm:"type:uuid;index;not null" json:"category_id"`
	Quantity        int       `gorm:"default:1;not null" json:"quantity"`
	Unit            string    `gorm:"type:varchar(20)" json:"unit"`
	ExpiryDate      time.Time `gorm:"type:date;index;not null" json:"expiry_date"`
	StorageLocation string    `gorm:"type:varchar(100)" json:"storage_location"`
	Status          string    `gorm:"type:varchar(20);index;not null" json:"status"`
	Notes           string    `gorm:"type:text" json:"notes"`
	DeviceID        string    `gorm:"type:varchar(255);index;not null" json:"device_id"`

	Category *Category `gorm:"foreignKey:CategoryID" json:"category,omitempty"`
}

func (Item) TableName() string {
	return "items"
}

func (item *Item) BeforeSave(tx *gorm.DB) error {
	item.Status = CalculateStatus(item.ExpiryDate)
	return nil
}

func CalculateStatus(expiryDate time.Time) string {
	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
	expiry := time.Date(expiryDate.Year(), expiryDate.Month(), expiryDate.Day(), 0, 0, 0, 0, expiryDate.Location())

	days := int(expiry.Sub(today).Hours() / 24)

	if days < 0 {
		return StatusExpired
	}
	if days <= 7 {
		return StatusWarning
	}
	return StatusSafe
}

type Purchase struct {
	BaseModel
	DeviceID    string    `gorm:"type:varchar(255);index;not null" json:"device_id"`
	PurchasedAt time.Time `gorm:"not null" json:"purchased_at"`
	Amount      int       `gorm:"not null" json:"amount"`
}

func (Purchase) TableName() string {
	return "purchases"
}
