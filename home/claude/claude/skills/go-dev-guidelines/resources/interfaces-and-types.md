# Interfaces and Types in Go

Complete guide to interface design and type patterns.

## Table of Contents

- [Interface Design](#interface-design)
- [Functional Options](#functional-options)
- [Struct Embedding](#struct-embedding)
- [Type Assertions](#type-assertions)
- [Generics](#generics)

---

## Interface Design

### Small Interfaces

```go
// Good: Single-method interface
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

// Good: Compose when needed
type ReadWriter interface {
    Reader
    Writer
}
```

### Define at Consumer

```go
// Bad: Provider defines large interface
package user

type UserService interface {
    Create(ctx context.Context, u User) error
    Get(ctx context.Context, id string) (*User, error)
    Update(ctx context.Context, u User) error
    Delete(ctx context.Context, id string) error
    List(ctx context.Context, opts ListOptions) ([]User, error)
}

// Good: Consumer defines what it needs
package notification

// Only need what this package uses
type UserGetter interface {
    Get(ctx context.Context, id string) (*user.User, error)
}

type NotificationService struct {
    users UserGetter  // Accepts any type with Get method
}
```

### Accept Interface, Return Struct

```go
// Good: Accept interface for flexibility
func ProcessData(r io.Reader) error {
    // Works with files, HTTP bodies, buffers, etc.
}

// Good: Return concrete type for clarity
func NewUserService(repo UserRepository) *UserService {
    return &UserService{repo: repo}
}
```

### Optional Behavior

```go
// Check if type supports optional method
type Flusher interface {
    Flush() error
}

func writeData(w io.Writer, data []byte) error {
    if _, err := w.Write(data); err != nil {
        return err
    }

    // Flush if supported
    if f, ok := w.(Flusher); ok {
        return f.Flush()
    }
    return nil
}
```

---

## Functional Options

Pattern for flexible, extensible configuration.

### Basic Pattern

```go
type Server struct {
    addr    string
    timeout time.Duration
    logger  *slog.Logger
    maxConn int
}

type Option func(*Server)

func WithAddress(addr string) Option {
    return func(s *Server) {
        s.addr = addr
    }
}

func WithTimeout(d time.Duration) Option {
    return func(s *Server) {
        s.timeout = d
    }
}

func WithLogger(l *slog.Logger) Option {
    return func(s *Server) {
        s.logger = l
    }
}

func WithMaxConnections(n int) Option {
    return func(s *Server) {
        s.maxConn = n
    }
}

func NewServer(opts ...Option) *Server {
    // Defaults
    s := &Server{
        addr:    ":8080",
        timeout: 30 * time.Second,
        logger:  slog.Default(),
        maxConn: 100,
    }

    // Apply options
    for _, opt := range opts {
        opt(s)
    }

    return s
}
```

### Usage

```go
// Use defaults
server := NewServer()

// Customize
server := NewServer(
    WithAddress(":9090"),
    WithTimeout(60*time.Second),
    WithLogger(myLogger),
)
```

### With Validation

```go
type Option func(*Server) error

func WithPort(port int) Option {
    return func(s *Server) error {
        if port < 1 || port > 65535 {
            return fmt.Errorf("invalid port: %d", port)
        }
        s.addr = fmt.Sprintf(":%d", port)
        return nil
    }
}

func NewServer(opts ...Option) (*Server, error) {
    s := &Server{addr: ":8080"}

    for _, opt := range opts {
        if err := opt(s); err != nil {
            return nil, err
        }
    }

    return s, nil
}
```

---

## Struct Embedding

### Composition Over Inheritance

```go
type Logger struct {
    prefix string
}

func (l *Logger) Log(msg string) {
    fmt.Printf("[%s] %s\n", l.prefix, msg)
}

// Embed Logger to gain its methods
type Service struct {
    Logger  // Embedded, not named field
    repo Repository
}

func (s *Service) DoWork() {
    s.Log("starting work")  // Calls embedded Logger.Log
    // ...
    s.Log("work complete")
}
```

### Interface Embedding

```go
type ReadCloser struct {
    io.Reader  // Embed interface
    close func() error
}

func (rc *ReadCloser) Close() error {
    return rc.close()
}

// Now ReadCloser satisfies io.ReadCloser
```

### Shadowing Methods

```go
type Base struct{}

func (b *Base) Method() string {
    return "base"
}

type Extended struct {
    Base
}

// Override embedded method
func (e *Extended) Method() string {
    return "extended: " + e.Base.Method()
}
```

---

## Type Assertions

### Basic Type Assertion

```go
func process(v any) {
    // Assert type, panic if wrong
    s := v.(string)

    // Safe assertion with ok
    s, ok := v.(string)
    if !ok {
        // v is not a string
    }
}
```

### Type Switch

```go
func describe(v any) string {
    switch x := v.(type) {
    case string:
        return fmt.Sprintf("string of length %d", len(x))
    case int:
        return fmt.Sprintf("integer %d", x)
    case []byte:
        return fmt.Sprintf("bytes of length %d", len(x))
    case nil:
        return "nil"
    default:
        return fmt.Sprintf("unknown type %T", x)
    }
}
```

### Interface Check

```go
// Check if type implements interface
type Stringer interface {
    String() string
}

func toString(v any) string {
    if s, ok := v.(Stringer); ok {
        return s.String()
    }
    return fmt.Sprintf("%v", v)
}
```

---

## Generics

Go 1.18+ generics for type-safe reusable code.

### Basic Generic Function

```go
func Min[T constraints.Ordered](a, b T) T {
    if a < b {
        return a
    }
    return b
}

// Usage
minInt := Min(1, 2)       // int
minStr := Min("a", "b")   // string
```

### Generic Types

```go
type Stack[T any] struct {
    items []T
}

func (s *Stack[T]) Push(item T) {
    s.items = append(s.items, item)
}

func (s *Stack[T]) Pop() (T, bool) {
    if len(s.items) == 0 {
        var zero T
        return zero, false
    }
    item := s.items[len(s.items)-1]
    s.items = s.items[:len(s.items)-1]
    return item, true
}

// Usage
stack := &Stack[int]{}
stack.Push(1)
stack.Push(2)
val, _ := stack.Pop()  // 2
```

### Type Constraints

```go
// Built-in constraints
import "golang.org/x/exp/constraints"

func Sum[T constraints.Integer | constraints.Float](nums []T) T {
    var total T
    for _, n := range nums {
        total += n
    }
    return total
}

// Custom constraint
type Number interface {
    int | int64 | float64
}

func Double[T Number](n T) T {
    return n * 2
}
```

### Generic Repository

```go
type Entity interface {
    GetID() string
}

type Repository[T Entity] struct {
    items map[string]T
}

func NewRepository[T Entity]() *Repository[T] {
    return &Repository[T]{
        items: make(map[string]T),
    }
}

func (r *Repository[T]) Save(entity T) {
    r.items[entity.GetID()] = entity
}

func (r *Repository[T]) Find(id string) (T, bool) {
    entity, ok := r.items[id]
    return entity, ok
}

// Usage
type User struct {
    ID   string
    Name string
}

func (u User) GetID() string { return u.ID }

repo := NewRepository[User]()
repo.Save(User{ID: "1", Name: "Alice"})
```

---

## Common Patterns

### Nil Interface Check

```go
// Careful: nil pointer in interface is not nil interface
var u *User = nil
var i any = u

if i == nil {
    // This is FALSE! Interface contains nil pointer
}

// Correct check
if u == nil {
    // Check the concrete type
}
```

### Empty Interface

```go
// any is alias for interface{}
func process(v any) {
    // v can be any type
}

// Use sparingly - prefer typed interfaces
```

### Interface Satisfaction Check

```go
// Compile-time check that type implements interface
var _ UserRepository = (*PostgresRepository)(nil)
var _ io.Reader = (*MyReader)(nil)
```

---

**Related Files:**
- [SKILL.md](../SKILL.md) - Main guide
- [testing.md](testing.md) - Testing with interfaces
- [project-structure.md](project-structure.md) - Package organization
