package utils

import (
	"fmt"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"github.com/silk-tree/wuxu-app/internal/config"
	"github.com/silk-tree/wuxu-app/internal/models"
)

var DB *gorm.DB

func Init(cfg *config.DatabaseConfig, logLevel string) error {
	var gormLogLevel logger.LogLevel
	switch logLevel {
	case "debug":
		gormLogLevel = logger.Info
	case "info":
		gormLogLevel = logger.Warn
	case "warn":
		gormLogLevel = logger.Error
	default:
		gormLogLevel = logger.Silent
	}

	db, err := gorm.Open(postgres.Open(cfg.DSN()), &gorm.Config{
		Logger: logger.Default.LogMode(gormLogLevel),
	})
	if err != nil {
		return fmt.Errorf("connect postgres failed: %w", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		return fmt.Errorf("get sql.DB failed: %w", err)
	}

	sqlDB.SetMaxOpenConns(cfg.MaxOpenConns)
	sqlDB.SetMaxIdleConns(cfg.MaxIdleConns)
	sqlDB.SetConnMaxLifetime(time.Duration(cfg.ConnMaxLifetime) * time.Second)

	if err := sqlDB.Ping(); err != nil {
		return fmt.Errorf("ping database failed: %w", err)
	}

	DB = db
	return nil
}

func AutoMigrate() error {
	if DB == nil {
		return fmt.Errorf("database not initialized")
	}
	return DB.AutoMigrate(
		&models.User{},
		&models.Category{},
		&models.Item{},
		&models.Purchase{},
	)
}

func SeedCategories() error {
	if DB == nil {
		return fmt.Errorf("database not initialized")
	}

	categories := []models.Category{
		{Value: "food", Label: "食品", Icon: "🍎", SortOrder: 1},
		{Value: "daily", Label: "日用品", Icon: "🧴", SortOrder: 2},
		{Value: "medicine", Label: "药品", Icon: "💊", SortOrder: 3},
		{Value: "other", Label: "其他", Icon: "📦", SortOrder: 4},
	}

	for _, cat := range categories {
		var count int64
		DB.Model(&models.Category{}).Where("value = ?", cat.Value).Count(&count)
		if count == 0 {
			if err := DB.Create(&cat).Error; err != nil {
				return err
			}
		}
	}

	return nil
}
