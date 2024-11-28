# Change these variables as necessary.
MAIN_PACKAGE_PATH := ./cmd/app-name
BINARY_NAME := app-name

MIGRATIONS := ./db/migrations
DB := ./data/db.sqlite

# To prevent migration conflicts, we keep track of the current schema.
CURRENT_SCHEMA := ./db/current-schema.sql

TEMPLATES_SRC := $(wildcard ./internal/templates/*.templ)
TEMPLATES_DST := $(patsubst %.templ,%_templ.go,$(TEMPLATES_SRC))

SQLC_SRC := $(wildcard ./db/sqlc/*.sql)
SQLC_DST := $(patsubst ./db/sqlc/%.sql,./internal/sqlc/%.sql.go,$(SQLC_SRC))

ifndef TMPDIR
	TMPDIR := /tmp/
endif

# ==================================================================================== #
# HELPERS
# ==================================================================================== #

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

.PHONY: confirm
confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ $${ans:-N} = y ]

.PHONY: no-dirty
no-dirty:
	git diff --exit-code

## install-tools: install all tools listed in tools.go
.PHONY: install-tools
install-tools: tidy
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(shell go env GOPATH)/bin v1.63.4
	go install github.com/Polo123456789/gpx@latest
	gpx i:install


# ==================================================================================== #
# QUALITY CONTROL
# ==================================================================================== #

## tidy: format code and tidy modfile
.PHONY: tidy
tidy:
	go fmt ./...
	go mod tidy -v

## audit: run quality control checks
.PHONY: audit
audit:
	go mod verify
	go vet ./...
	golangci-lint run
	go run golang.org/x/vuln/cmd/govulncheck@latest ./...
	go test -tags assert -race -buildvcs -vet=off ./...


# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

## test: run all tests
.PHONY: test
test:
	go test -tags assert -race -buildvcs ./...

## test/cover: run all tests and display coverage
.PHONY: test/cover
test/cover:
	go test -tags assert -race -buildvcs -coverprofile=${TMPDIR}/coverage.out ./...
	go tool cover -html=${TMPDIR}/coverage.out

.PHONY: templates
templates: $(TEMPLATES_DST)

$(TEMPLATES_DST) &: $(TEMPLATES_SRC)
	gpx templ generate -lazy

.PHONY: sqlc
sqlc: $(SQLC_DST)

$(SQLC_DST) &: $(SQLC_SRC)
	gpx sqlc generate

## build: build the application
.PHONY: build
build: templates sqlc
	# Include additional build steps, like TypeScript, SCSS or Tailwind
	# compilation here, or add them as dependencies to this target (faster)
	go build -tags assert -o=${TMPDIR}/bin/${BINARY_NAME} ${MAIN_PACKAGE_PATH}

## run: run the  application
.PHONY: run
run: build
	${TMPDIR}/bin/${BINARY_NAME}

## run/live: run the application with reloading on file changes
.PHONY: run/live
run/live:
	gpx air -c .air.toml --build.bin "${TMPDIR}/bin/${BINARY_NAME}"


# ==================================================================================== #
# OPERATIONS
# ==================================================================================== #

## push: push changes to the remote Git repository
.PHONY: push
push: no-dirty tidy audit
	git push

## production/deploy: deploy the application to production
.PHONY: production/deploy
production/deploy: build confirm push
	GOOS=linux GOARCH=amd64 go build -ldflags='-s' -o=${TMPDIR}/bin/linux_amd64/${BINARY_NAME} ${MAIN_PACKAGE_PATH}

# ==================================================================================== #
# Migrations
# ==================================================================================== #

## migration/status: show the status of migrations
.PHONY: migration/status
migration/status:
	@gpx goose -dir ${MIGRATIONS} sqlite3 ${DB} status


## migration/up: run all pending migrations
.PHONY: migration/up
migration/up:
	@gpx goose -dir ${MIGRATIONS} sqlite3 ${DB} up
	@sqlite3 ${DB} .schema > ${CURRENT_SCHEMA}

## migration/down: undo the last migration
.PHONY: migration/down
migration/down:
	@gpx goose -dir ${MIGRATIONS} sqlite3 ${DB} down
	@sqlite3 ${DB} .schema > ${CURRENT_SCHEMA}

## migration/create: create a new migration
.PHONY: migration/create
migration/create:
	@read -p "Enter migration name: " name; \
		gpx goose -dir ${MIGRATIONS} sqlite3 ${DB} create $$name sql
