package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"

	"github.com/charmbracelet/log"
	_ "modernc.org/sqlite"

	"github.com/Polo123456789/golang-web-template/internal/http"
)

// Set in config, you set that
const DEBUG = true

func main() {
	ctx, cancel := signal.NotifyContext(
		context.Background(),
		os.Interrupt, os.Kill,
	)

	var logger *slog.Logger
	if DEBUG {
		logger = slog.New(log.NewWithOptions(os.Stderr, log.Options{
			Level:           log.DebugLevel,
			ReportTimestamp: false,
			ReportCaller:    true,
			CallerOffset:    0,
		}))
	} else {
		logger = slog.New(slog.NewTextHandler(os.Stderr, nil))
	}

	server := http.NewServer(
		"0.0.0.0",
		8080,
		logger,
	)

	http.RunServer(ctx, cancel, server, logger)
}
