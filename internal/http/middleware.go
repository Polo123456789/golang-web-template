package http

import (
	"fmt"
	"log/slog"
	"net/http"
	"time"
)

type wrappedWritter struct {
	http.ResponseWriter
	statusCode int
}

func (w *wrappedWritter) WriteHeader(statusCode int) {
	w.statusCode = statusCode
	w.ResponseWriter.WriteHeader(statusCode)
}

func CanonicalLoggerMiddleware(logger *slog.Logger, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		ww := &wrappedWritter{w, http.StatusOK}
		next.ServeHTTP(ww, r)

		logger.LogAttrs(
			r.Context(),
			slog.LevelInfo,
			"Finished Request",
			slog.String("url", r.URL.String()),
			slog.String("method", r.Method),
			slog.Int("status_code", ww.statusCode),
			slog.Duration("duration", time.Since(start)),
			// You might want to add more stuff in here, like ips, the user that
			// made the request, or the request ID if you have one.
		)
	})
}

func RecoverMiddleware(logger *slog.Logger, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				logger.LogAttrs(
					r.Context(),
					slog.LevelError,
					"Panic Recovered",
					slog.String("path", r.URL.String()),
					slog.String("method", r.Method),
					slog.String("error", fmt.Sprintf("%v", err)),
				)
				http.Error(
					w,
					http.StatusText(http.StatusInternalServerError),
					http.StatusInternalServerError,
				)
			}
		}()
		next.ServeHTTP(w, r)
	})
}
