# Complete Go Examples

Full working examples demonstrating best practices.

## Table of Contents

- [Simple HTTP Service](#simple-http-service)
- [Service with Repository Pattern](#service-with-repository-pattern)
- [CLI Application](#cli-application)
- [Worker Service](#worker-service)

---

## Simple HTTP Service

Minimal but complete HTTP API.

### main.go

```go
package main

import (
    "context"
    "encoding/json"
    "errors"
    "log/slog"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"
)

func main() {
    logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

    mux := http.NewServeMux()
    mux.HandleFunc("GET /health", healthHandler)
    mux.HandleFunc("GET /users/{id}", getUserHandler)

    srv := &http.Server{
        Addr:         ":8080",
        Handler:      loggingMiddleware(logger)(mux),
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
    }

    ctx, cancel := signal.NotifyContext(context.Background(),
        syscall.SIGINT, syscall.SIGTERM)
    defer cancel()

    go func() {
        logger.Info("starting server", "addr", srv.Addr)
        if err := srv.ListenAndServe(); err != http.ErrServerClosed {
            logger.Error("server error", "error", err)
            os.Exit(1)
        }
    }()

    <-ctx.Done()
    logger.Info("shutting down")

    shutdownCtx, shutdownCancel := context.WithTimeout(
        context.Background(), 30*time.Second)
    defer shutdownCancel()

    srv.Shutdown(shutdownCtx)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func getUserHandler(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")

    user := map[string]string{
        "id":   id,
        "name": "User " + id,
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}

func loggingMiddleware(logger *slog.Logger) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()
            next.ServeHTTP(w, r)
            logger.Info("request",
                "method", r.Method,
                "path", r.URL.Path,
                "duration", time.Since(start),
            )
        })
    }
}
```

---

## Service with Repository Pattern

Layered architecture with dependency injection.

### domain/user.go

```go
package domain

import "errors"

var (
    ErrNotFound = errors.New("not found")
    ErrConflict = errors.New("already exists")
)

type User struct {
    ID    string `json:"id"`
    Email string `json:"email"`
    Name  string `json:"name"`
}

type CreateUserRequest struct {
    Email string `json:"email"`
    Name  string `json:"name"`
}

func (r *CreateUserRequest) Validate() error {
    if r.Email == "" {
        return errors.New("email is required")
    }
    if r.Name == "" {
        return errors.New("name is required")
    }
    return nil
}
```

### repository/user.go

```go
package repository

import (
    "context"
    "sync"

    "myapp/internal/domain"

    "github.com/google/uuid"
)

type UserRepository interface {
    FindByID(ctx context.Context, id string) (*domain.User, error)
    FindByEmail(ctx context.Context, email string) (*domain.User, error)
    Save(ctx context.Context, user *domain.User) error
}

// In-memory implementation
type memoryUserRepo struct {
    mu    sync.RWMutex
    users map[string]*domain.User
}

func NewMemoryUserRepository() UserRepository {
    return &memoryUserRepo{
        users: make(map[string]*domain.User),
    }
}

func (r *memoryUserRepo) FindByID(ctx context.Context, id string) (*domain.User, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()

    user, ok := r.users[id]
    if !ok {
        return nil, domain.ErrNotFound
    }
    return user, nil
}

func (r *memoryUserRepo) FindByEmail(ctx context.Context, email string) (*domain.User, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()

    for _, user := range r.users {
        if user.Email == email {
            return user, nil
        }
    }
    return nil, domain.ErrNotFound
}

func (r *memoryUserRepo) Save(ctx context.Context, user *domain.User) error {
    r.mu.Lock()
    defer r.mu.Unlock()

    if user.ID == "" {
        user.ID = uuid.NewString()
    }
    r.users[user.ID] = user
    return nil
}
```

### service/user.go

```go
package service

import (
    "context"
    "errors"
    "fmt"
    "log/slog"

    "myapp/internal/domain"
    "myapp/internal/repository"
)

type UserService struct {
    repo   repository.UserRepository
    logger *slog.Logger
}

func NewUserService(repo repository.UserRepository, logger *slog.Logger) *UserService {
    return &UserService{
        repo:   repo,
        logger: logger,
    }
}

func (s *UserService) GetUser(ctx context.Context, id string) (*domain.User, error) {
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("finding user %s: %w", id, err)
    }
    return user, nil
}

func (s *UserService) CreateUser(ctx context.Context, req domain.CreateUserRequest) (*domain.User, error) {
    if err := req.Validate(); err != nil {
        return nil, fmt.Errorf("validation: %w", err)
    }

    // Check for existing email
    _, err := s.repo.FindByEmail(ctx, req.Email)
    if err == nil {
        return nil, fmt.Errorf("email %s: %w", req.Email, domain.ErrConflict)
    }
    if !errors.Is(err, domain.ErrNotFound) {
        return nil, fmt.Errorf("checking email: %w", err)
    }

    user := &domain.User{
        Email: req.Email,
        Name:  req.Name,
    }

    if err := s.repo.Save(ctx, user); err != nil {
        return nil, fmt.Errorf("saving user: %w", err)
    }

    s.logger.Info("user created", "id", user.ID, "email", user.Email)
    return user, nil
}
```

### handler/user.go

```go
package handler

import (
    "encoding/json"
    "errors"
    "log/slog"
    "net/http"

    "myapp/internal/domain"
    "myapp/internal/service"
)

type UserHandler struct {
    svc    *service.UserService
    logger *slog.Logger
}

func NewUserHandler(svc *service.UserService, logger *slog.Logger) *UserHandler {
    return &UserHandler{svc: svc, logger: logger}
}

func (h *UserHandler) RegisterRoutes(mux *http.ServeMux) {
    mux.HandleFunc("GET /users/{id}", h.GetUser)
    mux.HandleFunc("POST /users", h.CreateUser)
}

func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")

    user, err := h.svc.GetUser(r.Context(), id)
    if err != nil {
        h.handleError(w, r, err)
        return
    }

    h.respondJSON(w, http.StatusOK, user)
}

func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var req domain.CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        h.respondError(w, http.StatusBadRequest, "invalid request body")
        return
    }

    user, err := h.svc.CreateUser(r.Context(), req)
    if err != nil {
        h.handleError(w, r, err)
        return
    }

    h.respondJSON(w, http.StatusCreated, user)
}

func (h *UserHandler) handleError(w http.ResponseWriter, r *http.Request, err error) {
    h.logger.Error("request failed",
        "method", r.Method,
        "path", r.URL.Path,
        "error", err,
    )

    switch {
    case errors.Is(err, domain.ErrNotFound):
        h.respondError(w, http.StatusNotFound, "not found")
    case errors.Is(err, domain.ErrConflict):
        h.respondError(w, http.StatusConflict, "already exists")
    default:
        h.respondError(w, http.StatusInternalServerError, "internal error")
    }
}

func (h *UserHandler) respondJSON(w http.ResponseWriter, status int, data any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(data)
}

func (h *UserHandler) respondError(w http.ResponseWriter, status int, message string) {
    h.respondJSON(w, status, map[string]string{"error": message})
}
```

### cmd/api/main.go

```go
package main

import (
    "context"
    "log/slog"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "myapp/internal/handler"
    "myapp/internal/repository"
    "myapp/internal/service"
)

func main() {
    logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

    // Wire dependencies
    repo := repository.NewMemoryUserRepository()
    svc := service.NewUserService(repo, logger)
    h := handler.NewUserHandler(svc, logger)

    mux := http.NewServeMux()
    h.RegisterRoutes(mux)

    srv := &http.Server{
        Addr:    ":8080",
        Handler: mux,
    }

    ctx, cancel := signal.NotifyContext(context.Background(),
        syscall.SIGINT, syscall.SIGTERM)
    defer cancel()

    go func() {
        logger.Info("starting server", "addr", srv.Addr)
        if err := srv.ListenAndServe(); err != http.ErrServerClosed {
            logger.Error("server error", "error", err)
        }
    }()

    <-ctx.Done()

    shutdownCtx, _ := context.WithTimeout(context.Background(), 30*time.Second)
    srv.Shutdown(shutdownCtx)
}
```

---

## CLI Application

Command-line tool with subcommands.

```go
package main

import (
    "context"
    "flag"
    "fmt"
    "os"
)

func main() {
    if len(os.Args) < 2 {
        printUsage()
        os.Exit(1)
    }

    ctx := context.Background()

    switch os.Args[1] {
    case "serve":
        if err := serveCmd(ctx, os.Args[2:]); err != nil {
            fmt.Fprintf(os.Stderr, "error: %v\n", err)
            os.Exit(1)
        }
    case "migrate":
        if err := migrateCmd(ctx, os.Args[2:]); err != nil {
            fmt.Fprintf(os.Stderr, "error: %v\n", err)
            os.Exit(1)
        }
    case "version":
        fmt.Println("v1.0.0")
    default:
        printUsage()
        os.Exit(1)
    }
}

func printUsage() {
    fmt.Println("Usage: myapp <command> [options]")
    fmt.Println("")
    fmt.Println("Commands:")
    fmt.Println("  serve    Start the HTTP server")
    fmt.Println("  migrate  Run database migrations")
    fmt.Println("  version  Print version")
}

func serveCmd(ctx context.Context, args []string) error {
    fs := flag.NewFlagSet("serve", flag.ExitOnError)
    port := fs.Int("port", 8080, "Port to listen on")
    fs.Parse(args)

    fmt.Printf("Starting server on port %d\n", *port)
    // Start server...
    return nil
}

func migrateCmd(ctx context.Context, args []string) error {
    fs := flag.NewFlagSet("migrate", flag.ExitOnError)
    dir := fs.String("dir", "./migrations", "Migrations directory")
    fs.Parse(args)

    fmt.Printf("Running migrations from %s\n", *dir)
    // Run migrations...
    return nil
}
```

---

## Worker Service

Background job processor with graceful shutdown.

```go
package main

import (
    "context"
    "log/slog"
    "os"
    "os/signal"
    "syscall"
    "time"

    "golang.org/x/sync/errgroup"
)

type Job struct {
    ID   string
    Data string
}

func main() {
    logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

    ctx, cancel := signal.NotifyContext(context.Background(),
        syscall.SIGINT, syscall.SIGTERM)
    defer cancel()

    jobs := make(chan Job, 100)

    g, ctx := errgroup.WithContext(ctx)

    // Job producer
    g.Go(func() error {
        return producer(ctx, jobs, logger)
    })

    // Workers
    for i := 0; i < 5; i++ {
        workerID := i
        g.Go(func() error {
            return worker(ctx, workerID, jobs, logger)
        })
    }

    if err := g.Wait(); err != nil {
        logger.Error("shutdown", "error", err)
    }

    logger.Info("shutdown complete")
}

func producer(ctx context.Context, jobs chan<- Job, logger *slog.Logger) error {
    defer close(jobs)

    ticker := time.NewTicker(time.Second)
    defer ticker.Stop()

    id := 0
    for {
        select {
        case <-ctx.Done():
            logger.Info("producer stopping")
            return nil
        case <-ticker.C:
            id++
            job := Job{ID: fmt.Sprintf("job-%d", id), Data: "payload"}

            select {
            case jobs <- job:
                logger.Info("job queued", "job_id", job.ID)
            case <-ctx.Done():
                return nil
            }
        }
    }
}

func worker(ctx context.Context, id int, jobs <-chan Job, logger *slog.Logger) error {
    logger.Info("worker started", "worker_id", id)

    for {
        select {
        case job, ok := <-jobs:
            if !ok {
                logger.Info("worker stopping", "worker_id", id)
                return nil
            }
            processJob(ctx, job, logger)
        case <-ctx.Done():
            logger.Info("worker stopping", "worker_id", id)
            return nil
        }
    }
}

func processJob(ctx context.Context, job Job, logger *slog.Logger) {
    logger.Info("processing job", "job_id", job.ID)
    time.Sleep(500 * time.Millisecond) // Simulate work
    logger.Info("job complete", "job_id", job.ID)
}
```

---

**Related Files:**
- [SKILL.md](../SKILL.md) - Main guide
- [project-structure.md](project-structure.md) - Project organization
- [http-patterns.md](http-patterns.md) - HTTP patterns
- [concurrency.md](concurrency.md) - Worker patterns
