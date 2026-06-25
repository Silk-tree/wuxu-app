package router

import (
	"net/http"

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
	categoryService := services.NewCategoryService(categoryRepo)
	categoryHandler := handlers.NewCategoryHandler(categoryService)
	healthHandler := handlers.NewHealthHandler()

	r.GET("/", healthHandler.Health)
	r.GET("/health", healthHandler.Health)
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	apiV1 := r.Group("/api/v1")
	{
		apiV1.GET("/categories", categoryHandler.List)

		auth := apiV1.Group("")
		auth.Use(middleware.JWTAuth())
		{
			auth.GET("/ping", func(c *gin.Context) {
				c.JSON(http.StatusOK, gin.H{"message": "pong"})
			})
		}
	}

	return r
}
