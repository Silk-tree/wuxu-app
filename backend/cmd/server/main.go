package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/silk-tree/wuxu-app/internal/config"
	"github.com/silk-tree/wuxu-app/internal/router"
	"github.com/silk-tree/wuxu-app/pkg/utils"
)

// @title           物序 API
// @version         1.0
// @description     物序 App V1.0 后端 API 服务
// @host            localhost:8080
// @BasePath        /api/v1
// @schemes         http
func main() {
	configPath := os.Getenv("CONFIG_PATH")
	if configPath == "" {
		configPath = "configs/config.yaml"
	}

	cfg, err := config.Load(configPath)
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	if err := config.Init(cfg.Log.Level, cfg.Log.Format); err != nil {
		log.Fatalf("初始化日志失败: %v", err)
	}
	defer config.Sync()

	config.Sugar.Infow("配置加载成功",
		"port", cfg.Server.Port,
		"mode", cfg.Server.Mode,
		"database", cfg.Database.DBName,
	)

	if err := utils.Init(&cfg.Database, cfg.Log.Level); err != nil {
		config.Sugar.Warnw("数据库连接失败，跳过迁移", "error", err)
	} else {
		config.Sugar.Info("数据库连接成功")

		if err := utils.AutoMigrate(); err != nil {
			config.Sugar.Warnw("数据库迁移失败", "error", err)
		} else {
			config.Sugar.Info("数据库迁移完成")
		}

		if err := utils.SeedCategories(); err != nil {
			config.Sugar.Warnw("分类数据初始化失败", "error", err)
		} else {
			config.Sugar.Info("分类数据初始化完成")
		}
	}

	r := router.SetupRouter(utils.DB, cfg.Server.Mode)

	go func() {
		addr := fmt.Sprintf(":%d", cfg.Server.Port)
		config.Sugar.Infow("启动服务", "addr", addr)
		if err := r.Run(addr); err != nil {
			config.Sugar.Fatalw("服务启动失败", "error", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	config.Sugar.Info("正在关闭服务...")
	config.Sugar.Info("服务已停止")
}
