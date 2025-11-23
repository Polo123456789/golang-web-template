package db

import (
	"database/sql"
	"embed"
	"log/slog"

	"github.com/pressly/goose/v3"
)

//go:embed migrations/*.sql
var migrations embed.FS

func AutoMigrate(db *sql.DB, logger *slog.Logger) error {
	logger.Info("Running migrations")

	goose.SetBaseFS(migrations)

	if err := goose.SetDialect("sqlite3"); err != nil {
		return err
	}

	if err := goose.Up(db, "migrations"); err != nil {
		return err
	}

	return nil
}
