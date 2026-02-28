---
name: go-dev-guidelines
description: Comprehensive Go development guide for building idiomatic, robust applications. Use when creating Go services, APIs, CLI tools, or working with goroutines, channels, error handling, context, interfaces, structs, testing, or package organization. Covers project layout (cmd/, internal/, pkg/), error wrapping, concurrency patterns, graceful shutdown, dependency injection, and modern Go 1.22+ features.
---

# Go Development Guidelines

## Purpose

Establish consistency and best practices for Go applications using modern, idiomatic patterns. This guide covers project structure, error handling, concurrency, testing, and performance optimization.

## When to Use This Skill

Automatically activates when working on:
- Creating or modifying Go services, APIs, or CLI tools
- Implementing error handling and custom error types
- Working with goroutines, channels, and concurrency
- Using context for cancellation and timeouts
- Designing interfaces and structs
- Organizing packages and project structure
- Writing tests and benchmarks
- Performance optimization

---

## Quick Start

### New Go Project Checklist

- [ ] **Project layout**: cmd/, internal/, pkg/ structure
- [ ] **go.mod**: Module initialization with proper path
- [ ] **Main package**: Small, imports from internal/
- [ ] **Error handling**: Wrap errors with context
- [ ] **Context**: Pass as first parameter
- [ ] **Graceful shutdown**: Signal handling
- [ ] **Logging**: Structured logging (slog)
- [ ] **Testing**: Table-driven tests
- [ ] **Linting**: golangci-lint configured

### New Feature Checklist

- [ ] **Interface**: Define at consumer, not provider
- [ ] **Errors**: Custom types or sentinel errors
- [ ] **Context**: Respect cancellation
- [ ] **Tests**: Unit + integration coverage
- [ ] **Docs**: Package and exported function comments

---

## Project Structure

### Standard Layout

```
myproject/
├── cmd/
│   └── myapp/
│       └── main.go          # Entry point (minimal)
├── internal/
│   ├── config/              # Configuration
│   ├── handler/             # HTTP/gRPC handlers
│   ├── service/             # Business logic
│   ├── repository/          # Data access
│   └── domain/              # Domain models
├── pkg/                     # Public reusable packages (optional)
├── api/                     # API definitions (OpenAPI, proto)
├── go.mod
├── go.sum
└── Makefile
```

**Key Principles:**
- `cmd/`: Entry points only, minimal code
- `internal/`: Private application code (cannot be imported externally)
- `pkg/`: Public libraries (only if building reusable components)

See [project-structure.md](resources/project-structure.md) for complete details.

---

## Core Principles (7 Key Rules)

### 1. Make the Zero Value Useful

```go
// Good: Works without initialization
var buf bytes.Buffer
buf.WriteString("hello")

// Good: Usable zero value
type Server struct {
    addr string
}
func (s *Server) Address() string {
    if s.addr == "" {
        return ":8080"
    }
    return s.addr
}
```

### 2. Accept Interfaces, Return Structs

```go
// Good: Accept interface
func ProcessData(r io.Reader) error {
    // Works with files, buffers, network connections...
}

// Good: Return concrete type
func NewUserService(repo UserRepository) *UserService {
    return &UserService{repo: repo}
}
```

### 3. Always Handle Errors with Context

```go
// Bad: Lost context
if err != nil {
    return err
}

// Good: Wrap with context
if err != nil {
    return fmt.Errorf("failed to fetch user %s: %w", userID, err)
}
```

### 4. Pass Context as First Parameter

```go
// Good: Context first, always
func (s *Service) GetUser(ctx context.Context, id string) (*User, error) {
    if err := ctx.Err(); err != nil {
        return nil, err
    }
    // ...
}
```

### 5. Keep Interfaces Small

```go
// Good: Single-method interface
type Reader interface {
    Read(p []byte) (n int, err error)
}

// Good: Compose when needed
type ReadCloser interface {
    Reader
    Closer
}
```

### 6. Use Dependency Injection

```go
// Good: Dependencies injected
type UserService struct {
    repo   UserRepository
    logger *slog.Logger
}

func NewUserService(repo UserRepository, logger *slog.Logger) *UserService {
    return &UserService{repo: repo, logger: logger}
}
```

### 7. Write Table-Driven Tests

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive", 2, 3, 5},
        {"negative", -1, -1, -2},
        {"zero", 0, 0, 0},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            if got := Add(tt.a, tt.b); got != tt.expected {
                t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.expected)
            }
        })
    }
}
```

---

## Error Handling

### Error Wrapping

```go
// Wrap errors with context
user, err := s.repo.FindByID(ctx, id)
if err != nil {
    return nil, fmt.Errorf("finding user %s: %w", id, err)
}

// Check wrapped errors
if errors.Is(err, sql.ErrNoRows) {
    return nil, ErrNotFound
}
```

### Sentinel Errors

```go
// Define sentinel errors for known conditions
var (
    ErrNotFound     = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrConflict     = errors.New("conflict")
)

// Usage
if errors.Is(err, ErrNotFound) {
    // Handle not found case
}
```

### Custom Error Types

```go
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error on %s: %s", e.Field, e.Message)
}

// Check error type
var valErr *ValidationError
if errors.As(err, &valErr) {
    // Handle validation error with field info
}
```

See [error-handling.md](resources/error-handling.md) for complete patterns.

---

## Concurrency Patterns

### Worker Pool

```go
func WorkerPool(ctx context.Context, jobs <-chan Job, workers int) <-chan Result {
    results := make(chan Result, workers)
    var wg sync.WaitGroup

    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for job := range jobs {
                select {
                case <-ctx.Done():
                    return
                case results <- process(job):
                }
            }
        }()
    }

    go func() {
        wg.Wait()
        close(results)
    }()

    return results
}
```

### Graceful Shutdown

```go
func main() {
    ctx, cancel := signal.NotifyContext(context.Background(),
        syscall.SIGINT, syscall.SIGTERM)
    defer cancel()

    srv := &http.Server{Addr: ":8080", Handler: handler}

    go func() {
        if err := srv.ListenAndServe(); err != http.ErrServerClosed {
            log.Fatal(err)
        }
    }()

    <-ctx.Done()

    shutdownCtx, shutdownCancel := context.WithTimeout(
        context.Background(), 30*time.Second)
    defer shutdownCancel()

    srv.Shutdown(shutdownCtx)
}
```

See [concurrency.md](resources/concurrency.md) for more patterns.

---

## HTTP Handler Patterns

### Handler Structure

```go
type Handler struct {
    service *Service
    logger  *slog.Logger
}

func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    id := r.PathValue("id") // Go 1.22+

    user, err := h.service.GetUser(ctx, id)
    if err != nil {
        h.handleError(w, r, err)
        return
    }

    h.respondJSON(w, http.StatusOK, user)
}

func (h *Handler) respondJSON(w http.ResponseWriter, status int, data any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(data)
}
```

### Go 1.22+ Routing

```go
mux := http.NewServeMux()

// Method-specific routing (Go 1.22+)
mux.HandleFunc("GET /users/{id}", h.GetUser)
mux.HandleFunc("POST /users", h.CreateUser)
mux.HandleFunc("PUT /users/{id}", h.UpdateUser)
mux.HandleFunc("DELETE /users/{id}", h.DeleteUser)
```

See [http-patterns.md](resources/http-patterns.md) for complete examples.

---

## Quick Reference

### Naming Conventions

| Item | Convention | Example |
|------|------------|---------|
| Package | short, lowercase | `user`, `auth` |
| Interface | -er suffix (if single method) | `Reader`, `Closer` |
| Exported | PascalCase | `UserService` |
| Unexported | camelCase | `userCache` |
| Acronyms | ALL CAPS | `HTTPHandler`, `ID` |
| Constants | PascalCase or ALL_CAPS | `MaxRetries`, `MAX_SIZE` |

### Common Imports

```go
import (
    "context"
    "errors"
    "fmt"
    "log/slog"
    "net/http"
    "time"
)
```

### HTTP Status Mapping

| Condition | Status Code |
|-----------|-------------|
| Success | 200 OK |
| Created | 201 Created |
| Validation error | 400 Bad Request |
| Unauthorized | 401 Unauthorized |
| Forbidden | 403 Forbidden |
| Not found | 404 Not Found |
| Conflict | 409 Conflict |
| Server error | 500 Internal Server Error |

---

## Anti-Patterns to Avoid

- Naked returns in long functions
- Using `panic` for control flow
- Passing context in struct fields
- Mixing value and pointer receivers
- Ignoring errors (even with `_`)
- Generic package names (`utils`, `helpers`, `common`)
- Excessive directory nesting
- Business logic in handlers
- Global mutable state

---

## Navigation Guide

| Need to... | Read this |
|------------|-----------|
| Understand project layout | [project-structure.md](resources/project-structure.md) |
| Handle errors properly | [error-handling.md](resources/error-handling.md) |
| Work with goroutines | [concurrency.md](resources/concurrency.md) |
| Build HTTP services | [http-patterns.md](resources/http-patterns.md) |
| Design interfaces | [interfaces-and-types.md](resources/interfaces-and-types.md) |
| Write effective tests | [testing.md](resources/testing.md) |
| Optimize performance | [performance.md](resources/performance.md) |
| Configure linting | [tooling.md](resources/tooling.md) |
| See complete examples | [complete-examples.md](resources/complete-examples.md) |

---

## Resource Files

### [project-structure.md](resources/project-structure.md)
Standard layout, package organization, naming conventions

### [error-handling.md](resources/error-handling.md)
Error wrapping, sentinel errors, custom types, errors.Is/As

### [concurrency.md](resources/concurrency.md)
Goroutines, channels, worker pools, errgroup, sync primitives

### [http-patterns.md](resources/http-patterns.md)
Handlers, middleware, routing (Go 1.22+), request validation

### [interfaces-and-types.md](resources/interfaces-and-types.md)
Interface design, functional options, struct embedding

### [testing.md](resources/testing.md)
Table-driven tests, mocking, benchmarks, integration tests

### [performance.md](resources/performance.md)
Memory optimization, sync.Pool, profiling, benchmarking

### [tooling.md](resources/tooling.md)
golangci-lint, go vet, staticcheck, Makefile patterns

### [complete-examples.md](resources/complete-examples.md)
Full service examples, refactoring guides

---

**Skill Status**: COMPLETE
**Line Count**: < 500
**Progressive Disclosure**: 9 resource files
