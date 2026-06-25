package middleware

import (
	"time"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"github.com/silk-tree/wuxu-app/internal/config"
)

func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery

		c.Next()

		cost := time.Since(start)
		statusCode := c.Writer.Status()
		clientIP := c.ClientIP()
		method := c.Request.Method
		errMsg := c.Errors.ByType(gin.ErrorTypePrivate).String()

		if config.Logger == nil {
			return
		}

		if statusCode >= 500 {
			config.Logger.Error(path,
				zap.Int("status", statusCode),
				zap.String("method", method),
				zap.String("path", path),
				zap.String("query", query),
				zap.String("ip", clientIP),
				zap.Duration("cost", cost),
				zap.String("error", errMsg),
			)
		} else if statusCode >= 400 {
			config.Logger.Warn(path,
				zap.Int("status", statusCode),
				zap.String("method", method),
				zap.String("path", path),
				zap.String("query", query),
				zap.String("ip", clientIP),
				zap.Duration("cost", cost),
			)
		} else {
			config.Logger.Info(path,
				zap.Int("status", statusCode),
				zap.String("method", method),
				zap.String("path", path),
				zap.String("query", query),
				zap.String("ip", clientIP),
				zap.Duration("cost", cost),
			)
		}
	}
}
