# Go Tooling Guide

Essential tools for Go development.

## Table of Contents

- [Essential Commands](#essential-commands)
- [golangci-lint](#golangci-lint)
- [Makefile Patterns](#makefile-patterns)
- [Go Modules](#go-modules)
- [Code Generation](#code-generation)

---

## Essential Commands

### Build and Run

```bash
# Build
go build ./...
go build -o bin/myapp ./cmd/myapp

# Run
go run ./cmd/myapp

# Install
go install ./cmd/myapp
```

### Testing

```bash
# Run all tests
go test ./...

# Verbose output
go test -v ./...

# With coverage
go test -cover ./...
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# Run specific test
go test -run TestUserService ./internal/user

# Run benchmarks
go test -bench=. ./...
go test -bench=. -benchmem ./...

# Race detection
go test -race ./...

# Short mode (skip slow tests)
go test -short ./...
```

### Code Quality

```bash
# Format code
go fmt ./...
gofmt -s -w .

# Vet (static analysis)
go vet ./...

# staticcheck
staticcheck ./...

# golangci-lint (all-in-one)
golangci-lint run
```

### Module Management

```bash
# Initialize module
go mod init github.com/user/project

# Add dependencies
go get github.com/pkg/errors
go get github.com/pkg/errors@v0.9.1

# Update dependencies
go get -u ./...
go get -u github.com/pkg/errors

# Tidy (remove unused)
go mod tidy

# Download dependencies
go mod download

# Verify checksums
go mod verify

# Show dependency graph
go mod graph
```

---

## golangci-lint

The standard meta-linter for Go.

### Installation

```bash
# Binary
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin

# Go install
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

### Basic Usage

```bash
# Run with defaults
golangci-lint run

# Specific directories
golangci-lint run ./internal/...

# Show all issues (not just new)
golangci-lint run --new=false

# Fix auto-fixable issues
golangci-lint run --fix
```

### Configuration (.golangci.yml)

```yaml
run:
  timeout: 5m
  tests: true

linters:
  enable:
    - errcheck      # Check error returns
    - govet         # Report suspicious constructs
    - staticcheck   # Static analysis
    - unused        # Check unused code
    - gosimple      # Simplify code
    - ineffassign   # Detect ineffectual assignments
    - typecheck     # Type checking
    - gofmt         # Check formatting
    - goimports     # Check imports
    - misspell      # Check spelling
    - gosec         # Security checks
    - unconvert     # Remove unnecessary conversions
    - gocritic      # Opinionated linter
    - revive        # Fast, configurable linter

linters-settings:
  errcheck:
    check-type-assertions: true
    check-blank: true

  govet:
    enable-all: true

  gocritic:
    enabled-tags:
      - diagnostic
      - style
      - performance

  revive:
    rules:
      - name: blank-imports
      - name: context-as-argument
      - name: context-keys-type
      - name: dot-imports
      - name: error-return
      - name: error-naming
      - name: exported
      - name: increment-decrement
      - name: var-naming
      - name: package-comments
      - name: range
      - name: receiver-naming
      - name: time-naming
      - name: unexported-return
      - name: indent-error-flow
      - name: errorf

issues:
  exclude-rules:
    # Ignore long lines in generated files
    - path: _gen\.go
      linters:
        - lll

    # Ignore magic numbers in tests
    - path: _test\.go
      linters:
        - gomnd

  max-issues-per-linter: 0
  max-same-issues: 0
```

### CI Integration

```yaml
# GitHub Actions
name: Lint

on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - name: golangci-lint
        uses: golangci/golangci-lint-action@v4
        with:
          version: latest
```

---

## Makefile Patterns

### Basic Makefile

```makefile
.PHONY: build test lint clean

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOTEST=$(GOCMD) test
GOVET=$(GOCMD) vet
BINARY_NAME=myapp
BINARY_DIR=bin

# Build info
VERSION ?= $(shell git describe --tags --always --dirty)
BUILD_TIME=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
LDFLAGS=-ldflags "-X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME)"

all: lint test build

build:
	$(GOBUILD) $(LDFLAGS) -o $(BINARY_DIR)/$(BINARY_NAME) ./cmd/$(BINARY_NAME)

test:
	$(GOTEST) -race -cover ./...

test-short:
	$(GOTEST) -short ./...

lint:
	golangci-lint run

fmt:
	gofmt -s -w .
	goimports -w .

vet:
	$(GOVET) ./...

clean:
	rm -rf $(BINARY_DIR)
	$(GOCMD) clean

run: build
	./$(BINARY_DIR)/$(BINARY_NAME)

# Dependencies
deps:
	$(GOCMD) mod download
	$(GOCMD) mod tidy

# Docker
docker-build:
	docker build -t $(BINARY_NAME):$(VERSION) .

# Generate
generate:
	$(GOCMD) generate ./...
```

### Advanced Makefile

```makefile
.PHONY: help build test lint

# Default target
.DEFAULT_GOAL := help

# Help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build the application
	go build -o bin/app ./cmd/app

test: ## Run tests
	go test -race ./...

test-coverage: ## Run tests with coverage
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

lint: ## Run linters
	golangci-lint run

bench: ## Run benchmarks
	go test -bench=. -benchmem ./...

install-tools: ## Install development tools
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install golang.org/x/tools/cmd/goimports@latest
```

---

## Go Modules

### Module Initialization

```bash
# Public module
go mod init github.com/username/project

# Private module
go mod init company.com/team/project
```

### Version Selection

```bash
# Latest version
go get github.com/pkg/errors

# Specific version
go get github.com/pkg/errors@v0.9.1

# Specific commit
go get github.com/pkg/errors@abc123

# Branch
go get github.com/pkg/errors@main

# Upgrade to latest
go get -u github.com/pkg/errors
```

### Workspace (Multi-Module)

```bash
# Initialize workspace
go work init ./module1 ./module2

# Add module to workspace
go work use ./module3
```

go.work file:
```
go 1.22

use (
    ./module1
    ./module2
)
```

### Replace Directive

```go
// go.mod
module myapp

go 1.22

require github.com/pkg/errors v0.9.1

// Local development override
replace github.com/pkg/errors => ../errors

// Fork override
replace github.com/original/pkg => github.com/fork/pkg v1.0.0
```

---

## Code Generation

### go generate

```go
//go:generate stringer -type=Status
//go:generate mockgen -source=repository.go -destination=mock_repository.go

type Status int

const (
    StatusPending Status = iota
    StatusActive
    StatusDone
)
```

Run: `go generate ./...`

### Common Generators

```bash
# Stringer (enum string methods)
go install golang.org/x/tools/cmd/stringer@latest

# Mockgen (mock generation)
go install go.uber.org/mock/mockgen@latest

# Wire (dependency injection)
go install github.com/google/wire/cmd/wire@latest

# sqlc (SQL to Go)
go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

# oapi-codegen (OpenAPI)
go install github.com/deepmap/oapi-codegen/v2/cmd/oapi-codegen@latest
```

### Example: Mock Generation

```go
// repository.go

//go:generate mockgen -source=repository.go -destination=mock_repository_test.go -package=user_test

type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, user *User) error
}
```

---

**Related Files:**
- [SKILL.md](../SKILL.md) - Main guide
- [testing.md](testing.md) - Testing commands
- [project-structure.md](project-structure.md) - Project layout
