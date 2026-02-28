# Testing in Go

Complete guide to writing effective tests.

## Table of Contents

- [Table-Driven Tests](#table-driven-tests)
- [Test Helpers](#test-helpers)
- [Mocking](#mocking)
- [Integration Tests](#integration-tests)
- [Benchmarks](#benchmarks)
- [Test Organization](#test-organization)

---

## Table-Driven Tests

The standard Go testing pattern.

### Basic Pattern

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive numbers", 2, 3, 5},
        {"negative numbers", -1, -2, -3},
        {"zero", 0, 0, 0},
        {"mixed", -1, 1, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.expected {
                t.Errorf("Add(%d, %d) = %d, want %d",
                    tt.a, tt.b, got, tt.expected)
            }
        })
    }
}
```

### With Error Cases

```go
func TestParseUser(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    *User
        wantErr bool
    }{
        {
            name:  "valid user",
            input: `{"id":"1","name":"Alice"}`,
            want:  &User{ID: "1", Name: "Alice"},
        },
        {
            name:    "invalid json",
            input:   `{invalid}`,
            wantErr: true,
        },
        {
            name:    "empty input",
            input:   "",
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseUser(tt.input)

            if tt.wantErr {
                if err == nil {
                    t.Error("expected error, got nil")
                }
                return
            }

            if err != nil {
                t.Errorf("unexpected error: %v", err)
                return
            }

            if !reflect.DeepEqual(got, tt.want) {
                t.Errorf("got %+v, want %+v", got, tt.want)
            }
        })
    }
}
```

### With Specific Error Types

```go
func TestGetUser(t *testing.T) {
    tests := []struct {
        name      string
        id        string
        want      *User
        wantErr   error
    }{
        {
            name: "existing user",
            id:   "123",
            want: &User{ID: "123", Name: "Alice"},
        },
        {
            name:    "not found",
            id:      "999",
            wantErr: ErrNotFound,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := svc.GetUser(context.Background(), tt.id)

            if tt.wantErr != nil {
                if !errors.Is(err, tt.wantErr) {
                    t.Errorf("got error %v, want %v", err, tt.wantErr)
                }
                return
            }

            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }

            if got.ID != tt.want.ID {
                t.Errorf("got ID %s, want %s", got.ID, tt.want.ID)
            }
        })
    }
}
```

---

## Test Helpers

### Helper Functions

```go
// t.Helper() marks function as helper - errors report caller's line
func assertEqual(t *testing.T, got, want any) {
    t.Helper()
    if !reflect.DeepEqual(got, want) {
        t.Errorf("got %v, want %v", got, want)
    }
}

func assertNoError(t *testing.T, err error) {
    t.Helper()
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

func assertError(t *testing.T, err, target error) {
    t.Helper()
    if !errors.Is(err, target) {
        t.Errorf("got error %v, want %v", err, target)
    }
}
```

### Setup and Teardown

```go
func TestDatabase(t *testing.T) {
    // Setup
    db := setupTestDB(t)

    // Teardown runs after test
    t.Cleanup(func() {
        db.Close()
    })

    // Test code
    t.Run("insert", func(t *testing.T) {
        // ...
    })
}

func setupTestDB(t *testing.T) *sql.DB {
    t.Helper()

    db, err := sql.Open("postgres", testDSN)
    if err != nil {
        t.Fatalf("failed to connect: %v", err)
    }

    return db
}
```

### Test Fixtures

```go
func TestUserService(t *testing.T) {
    // Load fixture
    data, err := os.ReadFile("testdata/users.json")
    if err != nil {
        t.Fatalf("failed to load fixture: %v", err)
    }

    var users []User
    if err := json.Unmarshal(data, &users); err != nil {
        t.Fatalf("failed to parse fixture: %v", err)
    }

    // Use fixtures in tests
}
```

---

## Mocking

### Interface-Based Mocking

```go
// Define interface for dependencies
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, user *User) error
}

// Mock implementation
type mockUserRepo struct {
    findByIDFunc func(ctx context.Context, id string) (*User, error)
    saveFunc     func(ctx context.Context, user *User) error
}

func (m *mockUserRepo) FindByID(ctx context.Context, id string) (*User, error) {
    if m.findByIDFunc != nil {
        return m.findByIDFunc(ctx, id)
    }
    return nil, errors.New("not implemented")
}

func (m *mockUserRepo) Save(ctx context.Context, user *User) error {
    if m.saveFunc != nil {
        return m.saveFunc(ctx, user)
    }
    return errors.New("not implemented")
}
```

### Using Mocks in Tests

```go
func TestUserService_GetUser(t *testing.T) {
    t.Run("returns user when found", func(t *testing.T) {
        expected := &User{ID: "123", Name: "Alice"}

        repo := &mockUserRepo{
            findByIDFunc: func(ctx context.Context, id string) (*User, error) {
                if id == "123" {
                    return expected, nil
                }
                return nil, ErrNotFound
            },
        }

        svc := NewUserService(repo)
        user, err := svc.GetUser(context.Background(), "123")

        assertNoError(t, err)
        assertEqual(t, user, expected)
    })

    t.Run("returns error when not found", func(t *testing.T) {
        repo := &mockUserRepo{
            findByIDFunc: func(ctx context.Context, id string) (*User, error) {
                return nil, ErrNotFound
            },
        }

        svc := NewUserService(repo)
        _, err := svc.GetUser(context.Background(), "999")

        assertError(t, err, ErrNotFound)
    })
}
```

### Verifying Calls

```go
type mockUserRepo struct {
    findByIDCalls []string  // Track calls
    findByIDFunc  func(ctx context.Context, id string) (*User, error)
}

func (m *mockUserRepo) FindByID(ctx context.Context, id string) (*User, error) {
    m.findByIDCalls = append(m.findByIDCalls, id)
    if m.findByIDFunc != nil {
        return m.findByIDFunc(ctx, id)
    }
    return nil, nil
}

func TestCaching(t *testing.T) {
    repo := &mockUserRepo{
        findByIDFunc: func(ctx context.Context, id string) (*User, error) {
            return &User{ID: id}, nil
        },
    }

    svc := NewCachedUserService(repo)

    // First call
    svc.GetUser(context.Background(), "123")
    // Second call (should use cache)
    svc.GetUser(context.Background(), "123")

    // Verify repo only called once
    if len(repo.findByIDCalls) != 1 {
        t.Errorf("expected 1 call, got %d", len(repo.findByIDCalls))
    }
}
```

---

## Integration Tests

### Build Tag Separation

```go
//go:build integration

package user_test

import (
    "testing"
)

func TestUserRepository_Integration(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }

    // Real database tests
}
```

Run with: `go test -tags=integration ./...`

### HTTP Handler Tests

```go
func TestGetUserHandler(t *testing.T) {
    svc := &mockUserService{
        getUserFunc: func(ctx context.Context, id string) (*User, error) {
            return &User{ID: id, Name: "Alice"}, nil
        },
    }

    handler := NewHandler(svc, slog.Default())

    req := httptest.NewRequest("GET", "/users/123", nil)
    req.SetPathValue("id", "123")  // Go 1.22+

    rec := httptest.NewRecorder()

    handler.GetUser(rec, req)

    if rec.Code != http.StatusOK {
        t.Errorf("got status %d, want %d", rec.Code, http.StatusOK)
    }

    var response User
    if err := json.NewDecoder(rec.Body).Decode(&response); err != nil {
        t.Fatalf("failed to decode response: %v", err)
    }

    if response.Name != "Alice" {
        t.Errorf("got name %s, want Alice", response.Name)
    }
}
```

### Testing with Context

```go
func TestWithTimeout(t *testing.T) {
    ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
    defer cancel()

    svc := &slowService{}

    _, err := svc.SlowOperation(ctx)
    if !errors.Is(err, context.DeadlineExceeded) {
        t.Errorf("expected deadline exceeded, got %v", err)
    }
}
```

---

## Benchmarks

### Basic Benchmark

```go
func BenchmarkProcess(b *testing.B) {
    data := generateTestData()

    b.ResetTimer()  // Don't count setup time

    for i := 0; i < b.N; i++ {
        Process(data)
    }
}
```

Run with: `go test -bench=. ./...`

### Sub-Benchmarks

```go
func BenchmarkSort(b *testing.B) {
    sizes := []int{100, 1000, 10000}

    for _, size := range sizes {
        b.Run(fmt.Sprintf("size=%d", size), func(b *testing.B) {
            data := generateData(size)

            b.ResetTimer()
            for i := 0; i < b.N; i++ {
                sort.Ints(data)
            }
        })
    }
}
```

### Memory Benchmarks

```go
func BenchmarkAllocations(b *testing.B) {
    b.ReportAllocs()

    for i := 0; i < b.N; i++ {
        _ = make([]byte, 1024)
    }
}
```

Run with: `go test -bench=. -benchmem ./...`

---

## Test Organization

### File Structure

```
user/
├── user.go
├── user_test.go         # Unit tests
├── user_integration_test.go  # Integration tests
└── testdata/
    └── fixtures.json    # Test fixtures
```

### Naming Conventions

```go
// Test function: Test<FunctionName>
func TestGetUser(t *testing.T) {}

// Test method: Test<Type>_<Method>
func TestUserService_GetUser(t *testing.T) {}

// Subtests describe scenario
t.Run("returns error when not found", func(t *testing.T) {})

// Benchmark: Benchmark<FunctionName>
func BenchmarkProcess(b *testing.B) {}
```

### Test Packages

```go
// Same package (whitebox testing)
package user

// Different package (blackbox testing)
package user_test

import "myapp/internal/user"
```

---

**Related Files:**
- [SKILL.md](../SKILL.md) - Main guide
- [interfaces-and-types.md](interfaces-and-types.md) - Interface mocking
- [http-patterns.md](http-patterns.md) - Handler testing
