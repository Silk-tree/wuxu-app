package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/silk-tree/wuxu-app/internal/services"
	"github.com/silk-tree/wuxu-app/pkg/utils"
)

type CategoryHandler struct {
	categoryService services.CategoryService
}

func NewCategoryHandler(categoryService services.CategoryService) *CategoryHandler {
	return &CategoryHandler{categoryService: categoryService}
}

// ListCategories godoc
// @Summary 获取分类列表
// @Description 返回所有物品分类
// @Tags categories
// @Accept json
// @Produce json
// @Success 200 {object} utils.Response{data=[]models.Category}
// @Router /api/v1/categories [get]
func (h *CategoryHandler) List(c *gin.Context) {
	categories, err := h.categoryService.List()
	if err != nil {
		c.JSON(http.StatusInternalServerError, utils.ServerError("获取分类列表失败"))
		return
	}
	c.JSON(http.StatusOK, utils.Success(categories))
}
