package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type HealthHandler struct{}

func NewHealthHandler() *HealthHandler {
	return &HealthHandler{}
}

// Health godoc
// @Summary 健康检查
// @Description 返回 API 服务运行状态
// @Tags health
// @Accept json
// @Produce json
// @Success 200 {object} utils.Response
// @Router / [get]
func (h *HealthHandler) Health(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "物序 API 服务运行中",
	})
}
