# Error Handling in Go

Complete guide to idiomatic error handling patterns.

## Table of Contents

- [Core Principles](#core-principles)
- [Error Wrapping](#error-wrapping)
- [Sentinel Errors](#sentinel-errors)
- [Custom Error Types](#custom-error-types)
- [errors.Is and errors.As](#errorsis-and-errorsas)
- [HTTP Error Responses](#http-error-responses)
- [Logging Errors](#logging-errors)

---

## Core Principles

### Never Ignore Errors

```go
// Bad: Silent failure
result, _ := doSomething()

// Good: Handle or propagate
result, err := doSomething()
if err != nil {
    return fmt.Errorf("doing something: %w", err)
}
```

### Add Context When Propagating

```go
// Bad: No context
if err != nil {
    return err
}

// Good: Contextual information
if err != nil {
    return fmt.Errorf("fetching user %s: %w", userID, err)
}
```

### Handle Errors Once

```go
// Bad: Log and return (handled twice)
if err != nil {
    log.Error("failed", "err", err)
    return err  // Caller will also log!
}

// Good: Either handle or return
if err != nil {
    return fmt.Errorf("operation failed: %w", err)
}
// Let the top-level handler log
```

---

## Error Wrapping

### Using fmt.Errorf with %w

```go
func (s *Service) GetUser(ctx context.Context, id string) (*User, error) {
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        // Wrap with context, preserve original error
        return nil, fmt.Errorf("finding user %s: %w", id, err)
    }
    return user, nil
}
```

### Building Error Chains

```go
// Repository layer
func (r *Repo) FindByID(ctx context.Context, id string) (*User, error) {
    row := r.db.QueryRowContext(ctx, query, id)
    if err := row.Scan(&user); err != nil {
        return nil, fmt.Errorf("scanning user row: %w", err)
    }
    return &user, nil
}

// Service layer
func (s *Service) GetUser(ctx context.Context, id string) (*User, error) {
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("getting user %s: %w", id, err)
    }
    return user, nil
}

// Handler layer
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    user, err := h.svc.GetUser(r.Context(), id)
    if err != nil {
        // Full chain: "getting user abc: finding user abc: scanning user row: sql: no rows"
        h.handleError(w, r, err)
        return
    }
}
```

---

## Sentinel Errors

Define package-level errors for known conditions.

### Defining Sentinel Errors

```go
package domain

import "errors"

var (
    ErrNotFound     = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
    ErrForbidden    = errors.New("forbidden")
    ErrConflict     = errors.New("already exists")
    ErrInvalidInput = errors.New("invalid input")
)
```

### Using Sentinel Errors

```go
func (s *Service) GetUser(ctx context.Context, id string) (*User, error) {
    user, err := s.repo.FindByID(ctx, id)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, fmt.Errorf("user %s: %w", id, domain.ErrNotFound)
        }
        return nil, fmt.Errorf("finding user %s: %w", id, err)
    }
    return user, nil
}

// Caller can check
user, err := svc.GetUser(ctx, id)
if errors.Is(err, domain.ErrNotFound) {
    // Handle 404
}
```

---

## Custom Error Types

For errors that need to carry additional data.

### Defining Custom Errors

```go
package domain

import "fmt"

// ValidationError carries field-level validation details
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error on %s: %s", e.Field, e.Message)
}

// NotFoundError includes the resource type and ID
type NotFoundError struct {
    Resource string
    ID       string
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s %s not found", e.Resource, e.ID)
}

// Is allows errors.Is to match ErrNotFound
func (e *NotFoundError) Is(target error) bool {
    return target == ErrNotFound
}
```

### Using Custom Errors

```go
func (s *Service) CreateUser(ctx context.Context, req CreateUserRequest) (*User, error) {
    if req.Email == "" {
        return nil, &domain.ValidationError{
            Field:   "email",
            Message: "email is required",
        }
    }
    // ...
}

// Caller extracts details
var valErr *domain.ValidationError
if errors.As(err, &valErr) {
    fmt.Printf("Field %s: %s\n", valErr.Field, valErr.Message)
}
```

---

## errors.Is and errors.As

### errors.Is - Check Error Identity

```go
// Check if error (or any wrapped error) matches a target
if errors.Is(err, sql.ErrNoRows) {
    return domain.ErrNotFound
}

if errors.Is(err, context.Canceled) {
    // Request was cancelled
    return nil
}

if errors.Is(err, context.DeadlineExceeded) {
    // Timeout occurred
}
```

### errors.As - Extract Error Type

```go
// Extract specific error type from chain
var netErr *net.OpError
if errors.As(err, &netErr) {
    fmt.Printf("Network error on %s: %v\n", netErr.Op, netErr.Err)
}

var pathErr *os.PathError
if errors.As(err, &pathErr) {
    fmt.Printf("Path error on %s: %v\n", pathErr.Path, pathErr.Err)
}
```

---

## HTTP Error Responses

### Error Response Structure

```go
type ErrorResponse struct {
    Error   string            `json:"error"`
    Code    string            `json:"code,omitempty"`
    Details map[string]string `json:"details,omitempty"`
}

func (h *Handler) respondError(w http.ResponseWriter, status int, err error) {
    resp := ErrorResponse{Error: err.Error()}

    // Add details for validation errors
    var valErr *domain.ValidationError
    if errors.As(err, &valErr) {
        resp.Code = "VALIDATION_ERROR"
        resp.Details = map[string]string{valErr.Field: valErr.Message}
    }

    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(resp)
}
```

### Mapping Errors to Status Codes

```go
func (h *Handler) handleError(w http.ResponseWriter, r *http.Request, err error) {
    // Log the full error chain
    h.logger.Error("request failed",
        "method", r.Method,
        "path", r.URL.Path,
        "error", err,
    )

    // Map to HTTP status
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
        // Don't expose internal errors to clients
        h.respondError(w, http.StatusInternalServerError,
            errors.New("internal server error"))
    }
}
```

---

## Logging Errors

### Structured Logging with slog

```go
import "log/slog"

func (s *Service) ProcessOrder(ctx context.Context, orderID string) error {
    order, err := s.repo.FindOrder(ctx, orderID)
    if err != nil {
        s.logger.Error("failed to find order",
            "order_id", orderID,
            "error", err,
        )
        return fmt.Errorf("finding order %s: %w", orderID, err)
    }
    return nil
}
```

### Log at Boundaries, Not Everywhere

```go
// Bad: Logging at every layer
func (r *Repo) Find(id string) (*User, error) {
    log.Printf("finding user %s", id)  // Don't log here
    // ...
}

func (s *Service) GetUser(id string) (*User, error) {
    log.Printf("getting user %s", id)  // Don't log here
    // ...
}

// Good: Log at the boundary (handler)
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    user, err := h.svc.GetUser(r.Context(), id)
    if err != nil {
        h.logger.Error("failed to get user", "id", id, "error", err)
        // ...
    }
}
```

---

**Related Files:**
- [SKILL.md](../SKILL.md) - Main guide
- [http-patterns.md](http-patterns.md) - HTTP error handling
- [testing.md](testing.md) - Testing error conditions
