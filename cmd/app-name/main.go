package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"

	"github.com/Polo123456789/golang-web-template/internal/http"
)

func main() {
	ctx, cancel := signal.NotifyContext(
		context.Background(),
		os.Interrupt, os.Kill,
	)

	logger := slog.New(slog.NewTextHandler(os.Stderr, nil))

	server := http.NewServer(
		"0.0.0.0",
		8080,
		logger,
	)

	http.RunServer(ctx, cancel, server, logger)
}
