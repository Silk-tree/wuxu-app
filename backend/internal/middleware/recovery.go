package middleware

import (
	"fmt"
	"net/http"
	"runtime/debug"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"github.com/silk-tree/wuxu-app/internal/config"
	"github.com/silk-tree/wuxu-app/pkg/utils"
)

func Recovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				if config.Logger != nil {
					config.Logger.Error("panic recovered",
						zap.Any("error", err),
						zap.String("stack", string(debug.Stack())),
					)
				} else {
					fmt.Printf("panic recovered: %v\n%s\n", err, debug.Stack())
				}
				c.AbortWithStatusJSON(http.StatusInternalServerError, utils.ServerError("服务器内部错误"))
			}
		}()
		c.Next()
	}
}
