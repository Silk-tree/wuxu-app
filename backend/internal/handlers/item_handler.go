package handlers

import (
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/silk-tree/wuxu-app/internal/models"
	"github.com/silk-tree/wuxu-app/internal/services"
	"github.com/silk-tree/wuxu-app/pkg/utils"
)

type CreateItemRequest struct {
	Name            string `json:"name" binding:"required"`
	CategoryID      string `json:"category_id" binding:"required"`
	Quantity        int    `json:"quantity"`
	Unit            string `json:"unit"`
	ExpiryDate      string `json:"expiry_date" binding:"required"`
	StorageLocation string `json:"storage_location"`
	Notes           string `json:"notes"`
}

type UpdateItemRequest struct {
	Name            string `json:"name"`
	CategoryID      string `json:"category_id"`
	Quantity        int    `json:"quantity"`
	Unit            string `json:"unit"`
	ExpiryDate      string `json:"expiry_date"`
	StorageLocation string `json:"storage_location"`
	Notes           string `json:"notes"`
}

type ItemHandler struct {
	itemService services.ItemService
}

func NewItemHandler(itemService services.ItemService) *ItemHandler {
	return &ItemHandler{itemService: itemService}
}

func getDeviceID(c *gin.Context) string {
	return c.GetHeader("X-Device-ID")
}

// CreateItem godoc
// @Summary 创建物品
// @Description 创建一个新的物品记录，未付费用户最多20条
// @Tags items
// @Accept json
// @Produce json
// @Param X-Device-ID header string true "设备标识"
// @Param request body CreateItemRequest true "物品信息"
// @Success 201 {object} utils.Response{data=models.Item}
// @Failure 400 {object} utils.Response
// @Failure 403 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /api/v1/items [post]
func (h *ItemHandler) Create(c *gin.Context) {
	deviceID := getDeviceID(c)
	if deviceID == "" {
		c.JSON(http.StatusBadRequest, utils.ParamError("缺少设备标识"))
		return
	}

	var req CreateItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.ParamError("请求参数错误"))
		return
	}

	if req.Name == "" {
		c.JSON(http.StatusBadRequest, utils.ParamError("物品名称不能为空"))
		return
	}

	categoryID, err := uuid.Parse(req.CategoryID)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ParamError("分类ID格式错误"))
		return
	}

	expiryDate, err := time.Parse("2006-01-02", req.ExpiryDate)
	if err != nil {
		c.JSON(http.StatusBadRequest, utils.ParamError("日期格式错误，应为 YYYY-MM-DD"))
		return
	}

	if req.Quantity < 1 {
		req.Quantity = 1
	}
	if req.Quantity > 999 {
		c.JSON(http.StatusBadRequest, utils.ParamError("数量应在 1-999 之间"))
		return
	}

	item := &models.Item{
		Name:            req.Name,
		CategoryID:      categoryID,
		Quantity:        req.Quantity,
		Unit:            req.Unit,
		ExpiryDate:      expiryDate,
		StorageLocation: req.StorageLocation,
		Notes:           req.Notes,
	}

	created, err := h.itemService.Create(deviceID, item)
	if err != nil {
		if errors.Is(err, services.ErrLimitExceeded) {
			c.JSON(http.StatusForbidden, utils.LimitExceeded("免费用户物品数量已达上限，请付费解锁"))
			return
		}
		c.JSON(http.StatusInternalServerError, utils.ServerError("创建物品失败"))
		return
	}

	c.JSON(http.StatusCreated, utils.Success(created))
}

// ListItems godoc
// @Summary 获取物品列表
// @Description 获取用户的物品列表，支持按状态筛选和排序
// @Tags items
// @Accept json
// @Produce json
// @Param X-Device-ID header string true "设备标识"
// @Param status query string false "状态筛选 (safe/warning/expired)"
// @Param category_id query string false "分类ID筛选"
// @Param sort query string false "排序方式 (expiry_asc/expiry_desc/created_desc)"
// @Param limit query int false "每页数量，默认50"
// @Param offset query int false "偏移量，默认0"
// @Success 200 {object} utils.Response{data=services.ItemListResult}
// @Failure 400 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /api/v1/items [get]
func (h *ItemHandler) List(c *gin.Context) {
	deviceID := getDeviceID(c)
	if deviceID == "" {
		c.JSON(http.StatusBadRequest, utils.ParamError("缺少设备标识"))
		return
	}

	status := c.Query("status")
	categoryID := c.Query("category_id")
	sort := c.Query("sort")

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	result, err := h.itemService.List(deviceID, status, categoryID, sort, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.ServerError("获取物品列表失败"))
		return
	}

	c.JSON(http.StatusOK, utils.Success(result))
}

// GetItem godoc
// @Summary 获取物品详情
// @Description 根据ID获取物品详情
// @Tags items
// @Accept json
// @Produce json
// @Param id path string true "物品ID"
// @Success 200 {object} utils.Response{data=models.Item}
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /api/v1/items/{id} [get]
func (h *ItemHandler) Get(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, utils.ParamError("缺少物品ID"))
		return
	}

	item, err := h.itemService.GetByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, utils.NotFound("物品不存在"))
		return
	}

	c.JSON(http.StatusOK, utils.Success(item))
}

// UpdateItem godoc
// @Summary 更新物品
// @Description 更新物品信息
// @Tags items
// @Accept json
// @Produce json
// @Param id path string true "物品ID"
// @Param request body UpdateItemRequest true "物品信息"
// @Success 200 {object} utils.Response{data=models.Item}
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /api/v1/items/{id} [put]
func (h *ItemHandler) Update(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, utils.ParamError("缺少物品ID"))
		return
	}

	var req UpdateItemRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, utils.ParamError("请求参数错误"))
		return
	}

	existing, err := h.itemService.GetByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, utils.NotFound("物品不存在"))
		return
	}

	if req.Name != "" {
		existing.Name = req.Name
	}
	if req.CategoryID != "" {
		categoryID, err := uuid.Parse(req.CategoryID)
		if err != nil {
			c.JSON(http.StatusBadRequest, utils.ParamError("分类ID格式错误"))
			return
		}
		existing.CategoryID = categoryID
	}
	if req.Quantity > 0 && req.Quantity <= 999 {
		existing.Quantity = req.Quantity
	}
	if req.Unit != "" {
		existing.Unit = req.Unit
	}
	if req.ExpiryDate != "" {
		expiryDate, err := time.Parse("2006-01-02", req.ExpiryDate)
		if err != nil {
			c.JSON(http.StatusBadRequest, utils.ParamError("日期格式错误"))
			return
		}
		existing.ExpiryDate = expiryDate
	}
	if req.StorageLocation != "" {
		existing.StorageLocation = req.StorageLocation
	}
	if req.Notes != "" {
		existing.Notes = req.Notes
	}

	updated, err := h.itemService.Update(id, existing)
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.ServerError("更新物品失败"))
		return
	}

	c.JSON(http.StatusOK, utils.Success(updated))
}

// DeleteItem godoc
// @Summary 删除物品
// @Description 删除指定物品
// @Tags items
// @Accept json
// @Produce json
// @Param id path string true "物品ID"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.Response
// @Failure 404 {object} utils.Response
// @Failure 500 {object} utils.Response
// @Router /api/v1/items/{id} [delete]
func (h *ItemHandler) Delete(c *gin.Context) {
	id := c.Param("id")
	if id == "" {
		c.JSON(http.StatusBadRequest, utils.ParamError("缺少物品ID"))
		return
	}

	if err := h.itemService.Delete(id); err != nil {
		c.JSON(http.StatusNotFound, utils.NotFound("物品不存在"))
		return
	}

	c.JSON(http.StatusOK, utils.SuccessNoData())
}