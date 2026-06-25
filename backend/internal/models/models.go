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

type User struct {
	BaseModel
	DeviceID           string    `gorm:"type:varchar(255);uniqueIndex;not null" json:"device_id"`
	HasUnlocked        bool      `gorm:"default:false;not null" json:"has_unlocked"`
	NotificationEnabled bool     `gorm:"default:true;not null" json:"notification_enabled"`
	ItemCount          int       `gorm:"default:0;not null" json:"item_count"`
}

func (User) TableName() string {
	return "users"
}

type Category struct {
	BaseModel
	Value     string `gorm:"type:varchar(50);uniqueIndex;not null" json:"value"`
	Label     string `gorm:"type:varchar(50);not null" json:"label"`
	Icon      string `gorm:"type:varchar(10);not null" json:"icon"`
	SortOrder int    `gorm:"default:0;not null" json:"sort_order"`
}

func (Category) TableName() string {
	return "categories"
}

type Item struct {
	BaseModel
	UserID     uuid.UUID `gorm:"type:uuid;index;not null" json:"user_id"`
	CategoryID uuid.UUID `gorm:"type:uuid;index;not null" json:"category_id"`
	Name       string    `gorm:"type:varchar(50);not null" json:"name"`
	ExpiryDate time.Time `gorm:"type:date;index;not null" json:"expiry_date"`
	Quantity   int       `gorm:"default:1;not null;check:quantity >= 1 AND quantity <= 999" json:"quantity"`
	Location   string    `gorm:"type:varchar(100)" json:"location"`

	Category *Category `gorm:"foreignKey:CategoryID" json:"category,omitempty"`
}

func (Item) TableName() string {
	return "items"
}

type Purchase struct {
	BaseModel
	UserID        uuid.UUID `gorm:"type:uuid;index;not null" json:"user_id"`
	ProductID     string    `gorm:"type:varchar(50);not null" json:"product_id"`
	Amount        float64   `gorm:"type:decimal(10,2);not null" json:"amount"`
	Currency      string    `gorm:"type:varchar(3);default:CNY;not null" json:"currency"`
	TransactionID string    `gorm:"type:varchar(255);uniqueIndex;not null" json:"transaction_id"`
	PaymentMethod string    `gorm:"type:varchar(20);not null" json:"payment_method"`
	PaidAt        time.Time `gorm:"not null" json:"paid_at"`
}

func (Purchase) TableName() string {
	return "purchases"
}
