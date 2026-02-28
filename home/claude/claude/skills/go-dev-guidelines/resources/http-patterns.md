# HTTP Patterns in Go

Complete guide to building HTTP services with Go.

## Table of Contents

- [Handler Structure](#handler-structure)
- [Routing (Go 1.22+)](#routing-go-122)
- [Middleware](#middleware)
- [Request Handling](#request-handling)
- [Response Helpers](#response-helpers)
- [Validation](#validation)
- [Complete Example](#complete-example)

---

## Handler Structure

### Basic Handler Type

```go
type Handler struct {
    service *Service
    logger  *slog.Logger
}

func NewHandler(svc *Service, logger *slog.Logger) *Handler {
    return &Handler{
        service: svc,
        logger:  logger,
    }
}
```

### Handler Methods

```go
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    id := r.PathValue("id")  // Go 1.22+

    user, err := h.service.GetUser(ctx, id)
    if err != nil {
        h.handleError(w, r, err)
        return
    }

    h.respondJSON(w, http.StatusOK, user)
}

func (h *Handler) CreateUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    var req CreateUserRequest
    if err := h.decodeJSON(r, &req); err != nil {
        h.respondError(w, http.StatusBadRequest, err)
        return
    }

    user, err := h.service.CreateUser(ctx, req)
    if err != nil {
        h.handleError(w, r, err)
        return
    }

    h.respondJSON(w, http.StatusCreated, user)
}
```

---

## Routing (Go 1.22+)

Go 1.22 introduced enhanced routing in the standard library.

### Basic Routing

```go
func (h *Handler) RegisterRoutes(mux *http.ServeMux) {
    // Method + path pattern
    mux.HandleFunc("GET /users", h.ListUsers)
    mux.HandleFunc("POST /users", h.CreateUser)
    mux.HandleFunc("GET /users/{id}", h.GetUser)
    mux.HandleFunc("PUT /users/{id}", h.UpdateUser)
    mux.HandleFunc("DELETE /users/{id}", h.DeleteUser)

    // Nested resources
    mux.HandleFunc("GET /users/{userID}/orders", h.ListUserOrders)
    mux.HandleFunc("GET /users/{userID}/orders/{orderID}", h.GetUserOrder)
}
```

### Path Parameters

```go
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    // Extract path parameter
    id := r.PathValue("id")

    // Multiple parameters
    userID := r.PathValue("userID")
    orderID := r.PathValue("orderID")
}
```

### Query Parameters

```go
func (h *Handler) ListUsers(w http.ResponseWriter, r *http.Request) {
    query := r.URL.Query()

    // Single value
    search := query.Get("search")

    // With default
    limit := query.Get("limit")
    if limit == "" {
        limit = "20"
    }

    // Parse integer
    page, _ := strconv.Atoi(query.Get("page"))
    if page < 1 {
        page = 1
    }
}
```

---

## Middleware

### Middleware Function

```go
type Middleware func(http.Handler) http.Handler

func Chain(h http.Handler, middlewares ...Middleware) http.Handler {
    for i := len(middlewares) - 1; i >= 0; i-- {
        h = middlewares[i](h)
    }
    return h
}
```

### Logging Middleware

```go
func LoggingMiddleware(logger *slog.Logger) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()

            // Wrap response writer to capture status
            wrapped := &responseWriter{ResponseWriter: w, status: http.StatusOK}

            next.ServeHTTP(wrapped, r)

            logger.Info("request completed",
                "method", r.Method,
                "path", r.URL.Path,
                "status", wrapped.status,
                "duration", time.Since(start),
            )
        })
    }
}

type responseWriter struct {
    http.ResponseWriter
    status int
}

func (w *responseWriter) WriteHeader(status int) {
    w.status = status
    w.ResponseWriter.WriteHeader(status)
}
```

### Authentication Middleware

```go
func AuthMiddleware(verifier TokenVerifier) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            token := r.Header.Get("Authorization")
            if token == "" {
                http.Error(w, "unauthorized", http.StatusUnauthorized)
                return
            }

            // Strip "Bearer " prefix
            token = strings.TrimPrefix(token, "Bearer ")

            claims, err := verifier.Verify(r.Context(), token)
            if err != nil {
                http.Error(w, "unauthorized", http.StatusUnauthorized)
                return
            }

            // Add claims to context
            ctx := context.WithValue(r.Context(), claimsKey, claims)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```

### Recovery Middleware

```go
func RecoveryMiddleware(logger *slog.Logger) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            defer func() {
                if err := recover(); err != nil {
                    logger.Error("panic recovered",
                        "error", err,
                        "stack", string(debug.Stack()),
                    )
                    http.Error(w, "internal server error",
                        http.StatusInternalServerError)
                }
            }()
            next.ServeHTTP(w, r)
        })
    }
}
```

### Request ID Middleware

```go
func RequestIDMiddleware() Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            requestID := r.Header.Get("X-Request-ID")
            if requestID == "" {
                requestID = uuid.NewString()
            }

            ctx := context.WithValue(r.Context(), requestIDKey, requestID)
            w.Header().Set("X-Request-ID", requestID)

            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```

---

## Request Handling

### Decoding JSON

```go
func (h *Handler) decodeJSON(r *http.Request, v any) error {
    if r.Body == nil {
        return errors.New("empty request body")
    }

    // Limit body size
    r.Body = http.MaxBytesReader(nil, r.Body, 1<<20)  // 1MB

    dec := json.NewDecoder(r.Body)
    dec.DisallowUnknownFields()

    if err := dec.Decode(v); err != nil {
        var syntaxErr *json.SyntaxError
        var unmarshalErr *json.UnmarshalTypeError

        switch {
        case errors.As(err, &syntaxErr):
            return fmt.Errorf("malformed JSON at position %d", syntaxErr.Offset)
        case errors.As(err, &unmarshalErr):
            return fmt.Errorf("invalid value for field %s", unmarshalErr.Field)
        case errors.Is(err, io.EOF):
            return errors.New("empty request body")
        default:
            return err
        }
    }

    return nil
}
```

### Getting Auth Context

```go
type contextKey string

const claimsKey contextKey = "claims"

func GetClaims(ctx context.Context) (*Claims, bool) {
    claims, ok := ctx.Value(claimsKey).(*Claims)
    return claims, ok
}

func (h *Handler) GetCurrentUser(w http.ResponseWriter, r *http.Request) {
    claims, ok := GetClaims(r.Context())
    if !ok {
        h.respondError(w, http.StatusUnauthorized, errors.New("not authenticated"))
        return
    }

    user, err := h.service.GetUser(r.Context(), claims.UserID)
    // ...
}
```

---

## Response Helpers

### JSON Response

```go
func (h *Handler) respondJSON(w http.ResponseWriter, status int, data any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)

    if data != nil {
        if err := json.NewEncoder(w).Encode(data); err != nil {
            h.logger.Error("failed to encode response", "error", err)
        }
    }
}
```

### Error Response

```go
type ErrorResponse struct {
    Error   string            `json:"error"`
    Code    string            `json:"code,omitempty"`
    Details map[string]string `json:"details,omitempty"`
}

func (h *Handler) respondError(w http.ResponseWriter, status int, err error) {
    h.respondJSON(w, status, ErrorResponse{Error: err.Error()})
}

func (h *Handler) handleError(w http.ResponseWriter, r *http.Request, err error) {
    h.logger.Error("request failed",
        "method", r.Method,
        "path", r.URL.Path,
        "error", err,
    )

    switch {
    case errors.Is(err, domain.ErrNotFound):
        h.respondError(w, http.StatusNotFound, err)
    case errors.Is(err, domain.ErrUnauthorized):
        h.respondError(w, http.StatusUnauthorized, err)
    case errors.Is(err, domain.ErrForbidden):
        h.respondError(w, http.StatusForbidden, err)
    case errors.Is(err, domain.ErrConflict):
        h.respondError(w, http.StatusConflict, err)
    case errors.Is(err, domain.ErrInvalidInput):
        h.respondError(w, http.StatusBadRequest, err)
    default:
        h.respondError(w, http.StatusInternalServerError,
            errors.New("internal server error"))
    }
}
```

---

## Validation

### Request Validation

```go
type CreateUserRequest struct {
    Email    string `json:"email"`
    Name     string `json:"name"`
    Password string `json:"password"`
}

func (r *CreateUserRequest) Validate() error {
    if r.Email == "" {
        return &domain.ValidationError{Field: "email", Message: "required"}
    }
    if !strings.Contains(r.Email, "@") {
        return &domain.ValidationError{Field: "email", Message: "invalid format"}
    }
    if len(r.Password) < 8 {
        return &domain.ValidationError{Field: "password", Message: "must be at least 8 characters"}
    }
    return nil
}
```

### Handler with Validation

```go
func (h *Handler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := h.decodeJSON(r, &req); err != nil {
        h.respondError(w, http.StatusBadRequest, err)
        return
    }

    if err := req.Validate(); err != nil {
        h.respondError(w, http.StatusBadRequest, err)
        return
    }

    user, err := h.service.CreateUser(r.Context(), req)
    if err != nil {
        h.handleError(w, r, err)
        return
    }

    h.respondJSON(w, http.StatusCreated, user)
}
```

---

## Complete Example

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
)

func main() {
    logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

    // Setup dependencies
    repo := NewUserRepository(db)
    svc := NewUserService(repo)
    handler := NewHandler(svc, logger)

    // Setup routes
    mux := http.NewServeMux()
    handler.RegisterRoutes(mux)

    // Apply middleware
    h := Chain(mux,
        RecoveryMiddleware(logger),
        RequestIDMiddleware(),
        LoggingMiddleware(logger),
    )

    srv := &http.Server{
        Addr:         ":8080",
        Handler:      h,
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    // Graceful shutdown
    ctx, cancel := signal.NotifyContext(context.Background(),
        syscall.SIGINT, syscall.SIGTERM)
    defer cancel()

    go func() {
        logger.Info("server starting", "addr", srv.Addr)
        if err := srv.ListenAndServe(); err != http.ErrServerClosed {
            logger.Error("server error", "error", err)
        }
    }()

    <-ctx.Done()

    shutdownCtx, shutdownCancel := context.WithTimeout(
        context.Background(), 30*time.Second)
    defer shutdownCancel()

    logger.Info("shutting down")
    srv.Shutdown(shutdownCtx)
}
```

---

**Related Files:**
- [SKILL.md](../SKILL.md) - Main guide
- [error-handling.md](error-handling.md) - Error patterns
- [concurrency.md](concurrency.md) - Graceful shutdown
