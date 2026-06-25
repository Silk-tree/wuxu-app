package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/silk-tree/wuxu-app/internal/services"
	"github.com/silk-tree/wuxu-app/pkg/utils"
)

type StatsHandler struct {
	statsService services.StatsService
}

func NewStatsHandler(statsService services.StatsService) *StatsHandler {
	return &StatsHandler{statsService: statsService}
}

// GetStats godoc
// @Summary 获取统计信息
// @Description 获取用户的物品统计信息
// @Tags stats
// @Accept json
// @Produce json
// @Param X-Device-ID header string true "设备标识"
// @Success 200 {object} utils.Response{data=services.StatsResult}
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /api/v1/stats [get]
func (h *StatsHandler) GetStats(c *gin.Context) {
	deviceID := c.GetHeader("X-Device-ID")
	if deviceID == "" {
		c.JSON(http.StatusBadRequest, utils.ParamError("缺少设备标识"))
		return
	}

	stats, err := h.statsService.GetStats(deviceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.ServerError("获取统计信息失败"))
		return
	}

	c.JSON(http.StatusOK, utils.Success(stats))
}