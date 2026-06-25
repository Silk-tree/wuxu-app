package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/silk-tree/wuxu-app/internal/services"
	"github.com/silk-tree/wuxu-app/pkg/utils"
)

type PurchaseRequest struct {
	DeviceID string `json:"device_id" binding:"required"`
}

type PurchaseHandler struct {
	purchaseService services.PurchaseService
}

func NewPurchaseHandler(purchaseService services.PurchaseService) *PurchaseHandler {
	return &PurchaseHandler{purchaseService: purchaseService}
}

// Purchase godoc
// @Summary 购买解锁
// @Description 模拟购买解锁，付费后可无限添加物品
// @Tags purchase
// @Accept json
// @Produce json
// @Param request body PurchaseRequest true "购买请求"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /api/v1/purchase [post]
func (h *PurchaseHandler) Purchase(c *gin.Context) {
	var req PurchaseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.ParamError("缺少设备标识"))
		return
	}

	purchase, err := h.purchaseService.Create(req.DeviceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.ServerError("购买失败"))
		return
	}

	if purchase == nil {
		c.JSON(http.StatusOK, utils.Success(gin.H{
			"success": true,
			"message": "已经解锁，无需重复购买",
		}))
		return
	}

	c.JSON(http.StatusOK, utils.Success(gin.H{
		"success":  true,
		"message":  "解锁成功",
		"amount":   purchase.Amount,
		"purchased_at": purchase.PurchasedAt,
	}))
}