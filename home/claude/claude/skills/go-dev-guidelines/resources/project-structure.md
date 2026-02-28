# Go Project Structure

Complete guide to organizing Go projects following modern conventions.

## Table of Contents

- [Standard Layout](#standard-layout)
- [Directory Descriptions](#directory-descriptions)
- [Package Naming](#package-naming)
- [When to Use Each Directory](#when-to-use-each-directory)
- [Small vs Large Projects](#small-vs-large-projects)

---

## Standard Layout

```
myproject/
├── cmd/
│   ├── api/
│   │   └── main.go           # API server entry point
│   └── worker/
│       └── main.go           # Background worker entry point
├── internal/
│   ├── config/
│   │   └── config.go         # Configuration loading
│   ├── domain/
│   │   ├── user.go           # Domain models
│   │   └── errors.go         # Domain errors
│   ├── handler/
│   │   ├── handler.go        # HTTP handlers
│   │   └── middleware.go     # HTTP middleware
│   ├── service/
│   │   └── user.go           # Business logic
│   └── repository/
│       ├── repository.go     # Repository interfaces
│       └── postgres/
│           └── user.go       # PostgreSQL implementation
├── pkg/                      # Public libraries (optional)
│   └── validator/
│       └── validator.go
├── api/
│   └── openapi.yaml          # API specification
├── migrations/
│   └── 001_initial.sql       # Database migrations
├── scripts/
│   └── setup.sh              # Development scripts
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

---

## Directory Descriptions

### `/cmd`

Entry points for executables. Each subdirectory is a separate binary.

```go
// cmd/api/main.go
package main

import (
    "context"
    "log"
    "os/signal"
    "syscall"

    "myproject/internal/config"
    "myproject/internal/handler"
    "myproject/internal/service"
)

func main() {
    ctx, cancel := signal.NotifyContext(context.Background(),
        syscall.SIGINT, syscall.SIGTERM)
    defer cancel()

    cfg := config.Load()
    svc := service.New(cfg)
    h := handler.New(svc)

    if err := h.Run(ctx, cfg.Port); err != nil {
        log.Fatal(err)
    }
}
```

**Rules:**
- Keep main.go minimal (< 50 lines)
- Wire dependencies here
- Handle signals and graceful shutdown

### `/internal`

Private application code. Go compiler enforces that these packages cannot be imported by external projects.

**Organize by feature, not by layer:**

```
# Good: Feature-based
internal/
├── user/
│   ├── handler.go
│   ├── service.go
│   └── repository.go
├── order/
│   ├── handler.go
│   ├── service.go
│   └── repository.go

# Acceptable: Layer-based (for smaller projects)
internal/
├── handler/
├── service/
└── repository/
```

### `/pkg`

Public packages intended for external use. Only create if:
- Building a library for others to import
- Creating genuinely reusable components

**Most applications don't need `/pkg`**. Use `internal/` by default.

### `/api`

API contract definitions:
- OpenAPI/Swagger specs
- Protocol buffer definitions
- JSON Schema files

### `/migrations`

Database migration files:
```
migrations/
├── 000001_create_users.up.sql
├── 000001_create_users.down.sql
├── 000002_add_email_index.up.sql
└── 000002_add_email_index.down.sql
```

---

## Package Naming

### Guidelines

| Rule | Good | Bad |
|------|------|-----|
| Short, concise | `user` | `userpackage` |
| Lowercase only | `httputil` | `httpUtil`, `http_util` |
| No plurals | `user` | `users` |
| Descriptive | `auth`, `cache` | `util`, `common` |
| No stuttering | `http.Client` | `http.HTTPClient` |

### Import Path Conventions

```go
// Group imports: std, external, internal
import (
    "context"
    "fmt"
    "net/http"

    "github.com/gorilla/mux"
    "go.uber.org/zap"

    "myproject/internal/config"
    "myproject/internal/service"
)
```

---

## When to Use Each Directory

### Use `internal/` When:
- Code is specific to this application
- You don't want external packages importing it
- Default choice for most code

### Use `pkg/` When:
- Building a library for external consumption
- Code is truly generic and reusable
- You're okay with external import stability guarantees

### Use `cmd/` When:
- Creating executable entry points
- Need multiple binaries from one repo

---

## Small vs Large Projects

### Small Project (CLI tool, simple service)

```
myproject/
├── main.go
├── config.go
├── handler.go
├── service.go
├── go.mod
└── go.sum
```

Start simple. Add directories as complexity grows.

### Medium Project

```
myproject/
├── cmd/
│   └── myapp/
│       └── main.go
├── internal/
│   ├── config/
│   ├── handler/
│   └── service/
├── go.mod
└── Makefile
```

### Large Project (Multiple services)

```
myproject/
├── cmd/
│   ├── api/
│   ├── worker/
│   └── migrate/
├── internal/
│   ├── user/
│   ├── order/
│   ├── payment/
│   └── shared/
├── pkg/
│   └── validator/
├── api/
├── migrations/
├── deployments/
├── scripts/
└── docs/
```

---

## Common Mistakes

### Excessive Nesting

```
# Bad
internal/services/user/handlers/http/v1/handler.go

# Good
internal/user/handler.go
```

### Generic Package Names

```
# Bad
internal/utils/helpers.go
internal/common/types.go

# Good
internal/validator/email.go
internal/httputil/response.go
```

### Circular Dependencies

```
# Bad: user imports order, order imports user
internal/user/ → internal/order/ → internal/user/

# Good: Extract shared types
internal/user/ → internal/domain/
internal/order/ → internal/domain/
```

---

**Related Files:**
- [SKILL.md](../SKILL.md) - Main guide
- [interfaces-and-types.md](interfaces-and-types.md) - Interface design
