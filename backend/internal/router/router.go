package router

import (
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
	"gorm.io/gorm"

	"github.com/silk-tree/wuxu-app/internal/handlers"
	"github.com/silk-tree/wuxu-app/internal/middleware"
	"github.com/silk-tree/wuxu-app/internal/repository"
	"github.com/silk-tree/wuxu-app/internal/services"
)

func SetupRouter(db *gorm.DB, mode string) *gin.Engine {
	gin.SetMode(mode)
	r := gin.New()

	r.Use(middleware.Recovery())
	r.Use(middleware.CORS())
	r.Use(middleware.Logger())

	categoryRepo := repository.NewCategoryRepository(db)
	itemRepo := repository.NewItemRepository(db)
	purchaseRepo := repository.NewPurchaseRepository(db)

	categoryService := services.NewCategoryService(categoryRepo)
	itemService := services.NewItemService(itemRepo, purchaseRepo)
	purchaseService := services.NewPurchaseService(purchaseRepo)
	statsService := services.NewStatsService(itemRepo, purchaseRepo)

	categoryHandler := handlers.NewCategoryHandler(categoryService)
	itemHandler := handlers.NewItemHandler(itemService)
	purchaseHandler := handlers.NewPurchaseHandler(purchaseService)
	statsHandler := handlers.NewStatsHandler(statsService)
	healthHandler := handlers.NewHealthHandler()

	r.GET("/", healthHandler.Health)
	r.GET("/health", healthHandler.Health)
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	apiV1 := r.Group("/api/v1")
	{
		apiV1.GET("/categories", categoryHandler.List)

		apiV1.POST("/purchase", purchaseHandler.Purchase)

		apiV1.GET("/items", itemHandler.List)
		apiV1.GET("/items/:id", itemHandler.Get)
		apiV1.POST("/items", itemHandler.Create)
		apiV1.PUT("/items/:id", itemHandler.Update)
		apiV1.DELETE("/items/:id", itemHandler.Delete)

		apiV1.GET("/stats", statsHandler.GetStats)
	}

	return r
}