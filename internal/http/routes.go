package http

import (
	"log/slog"
	"net/http"

	"github.com/Polo123456789/golang-web-template/internal/templates"
)

func setupRoutes(
	mux *http.ServeMux,
	logger *slog.Logger,
) {
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		content := templates.Index()
		content.Render(r.Context(), w)
	})
}
