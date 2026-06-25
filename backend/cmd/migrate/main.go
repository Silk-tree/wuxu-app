package main

import (
	"log"
	"os"

	"github.com/silk-tree/wuxu-app/internal/config"
	"github.com/silk-tree/wuxu-app/pkg/utils"
)

func main() {
	configPath := os.Getenv("CONFIG_PATH")
	if configPath == "" {
		configPath = "configs/config.yaml"
	}

	cfg, err := config.Load(configPath)
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	if err := utils.Init(&cfg.Database, cfg.Log.Level); err != nil {
		log.Fatalf("连接数据库失败: %v", err)
	}
	log.Println("数据库连接成功")

	if err := utils.AutoMigrate(); err != nil {
		log.Fatalf("数据库迁移失败: %v", err)
	}
	log.Println("数据库迁移完成")

	if err := utils.SeedCategories(); err != nil {
		log.Fatalf("分类数据初始化失败: %v", err)
	}
	log.Println("分类数据初始化完成")

	log.Println("迁移完成")
}
