//go:build tools
// +build tools

package main

import (
	_ "github.com/a-h/templ/cmd/templ"
	_ "github.com/pressly/goose/v3/cmd/goose"
	_ "github.com/sqlc-dev/sqlc/cmd/sqlc"
)