package utils

type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

const (
	CodeSuccess      = 0
	CodeParamError   = 1001
	CodeNotFound     = 1002
	CodeForbidden    = 1003
	CodeServerError  = 5001
	CodeAuthError    = 4001
	CodePayError     = 3001
	CodeLimitExceeded = 2001
)

func Forbidden(message string) Response {
	return Error(CodeForbidden, message)
}

func LimitExceeded(message string) Response {
	return Error(CodeLimitExceeded, message)
}

func Success(data interface{}) Response {
	return Response{
		Code:    CodeSuccess,
		Message: "success",
		Data:    data,
	}
}

func SuccessNoData() Response {
	return Response{
		Code:    CodeSuccess,
		Message: "success",
		Data:    nil,
	}
}

func Error(code int, message string) Response {
	return Response{
		Code:    code,
		Message: message,
		Data:    nil,
	}
}

func ParamError(message string) Response {
	return Error(CodeParamError, message)
}

func ServerError(message string) Response {
	return Error(CodeServerError, message)
}

func NotFound(message string) Response {
	return Error(CodeNotFound, message)
}

func AuthError(message string) Response {
	return Error(CodeAuthError, message)
}
