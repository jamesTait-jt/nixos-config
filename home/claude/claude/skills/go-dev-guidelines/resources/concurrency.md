# Concurrency Patterns in Go

Complete guide to goroutines, channels, and synchronization.

## Table of Contents

- [Core Concepts](#core-concepts)
- [Channel Patterns](#channel-patterns)
- [Worker Pool](#worker-pool)
- [errgroup](#errgroup)
- [Context and Cancellation](#context-and-cancellation)
- [Graceful Shutdown](#graceful-shutdown)
- [Sync Primitives](#sync-primitives)
- [Common Mistakes](#common-mistakes)

---

## Core Concepts

### Goroutines

```go
// Start a goroutine
go func() {
    // Runs concurrently
}()

// Always ensure goroutines can exit
go func(ctx context.Context) {
    for {
        select {
        case <-ctx.Done():
            return  // Exit when cancelled
        default:
            // Do work
        }
    }
}(ctx)
```

### Channels

```go
// Unbuffered: Synchronous send/receive
ch := make(chan int)

// Buffered: Async up to capacity
ch := make(chan int, 100)

// Send
ch <- value

// Receive
value := <-ch

// Close (sender only, never receiver)
close(ch)

// Range over channel (exits when closed)
for value := range ch {
    process(value)
}
```

---

## Channel Patterns

### Fan-Out (Distribute Work)

```go
func fanOut(input <-chan Job, workers int) []<-chan Result {
    outputs := make([]<-chan Result, workers)
    for i := 0; i < workers; i++ {
        outputs[i] = worker(input)
    }
    return outputs
}

func worker(jobs <-chan Job) <-chan Result {
    results := make(chan Result)
    go func() {
        defer close(results)
        for job := range jobs {
            results <- process(job)
        }
    }()
    return results
}
```

### Fan-In (Merge Results)

```go
func fanIn(inputs ...<-chan Result) <-chan Result {
    var wg sync.WaitGroup
    merged := make(chan Result)

    output := func(ch <-chan Result) {
        defer wg.Done()
        for result := range ch {
            merged <- result
        }
    }

    wg.Add(len(inputs))
    for _, ch := range inputs {
        go output(ch)
    }

    go func() {
        wg.Wait()
        close(merged)
    }()

    return merged
}
```

### Pipeline

```go
func pipeline(ctx context.Context, nums []int) <-chan int {
    // Stage 1: Generate
    gen := func() <-chan int {
        out := make(chan int)
        go func() {
            defer close(out)
            for _, n := range nums {
                select {
                case out <- n:
                case <-ctx.Done():
                    return
                }
            }
        }()
        return out
    }

    // Stage 2: Square
    square := func(in <-chan int) <-chan int {
        out := make(chan int)
        go func() {
            defer close(out)
            for n := range in {
                select {
                case out <- n * n:
                case <-ctx.Done():
                    return
                }
            }
        }()
        return out
    }

    return square(gen())
}
```

---

## Worker Pool

### Basic Worker Pool

```go
func WorkerPool(ctx context.Context, jobs <-chan Job, workers int) <-chan Result {
    results := make(chan Result, workers)
    var wg sync.WaitGroup

    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func(workerID int) {
            defer wg.Done()
            for {
                select {
                case job, ok := <-jobs:
                    if !ok {
                        return  // Channel closed
                    }
                    result := process(job)
                    select {
                    case results <- result:
                    case <-ctx.Done():
                        return
                    }
                case <-ctx.Done():
                    return
                }
            }
        }(i)
    }

    go func() {
        wg.Wait()
        close(results)
    }()

    return results
}
```

### Worker Pool with Rate Limiting

```go
func RateLimitedPool(ctx context.Context, jobs <-chan Job, workers int, rps int) <-chan Result {
    results := make(chan Result, workers)
    limiter := time.NewTicker(time.Second / time.Duration(rps))
    defer limiter.Stop()

    var wg sync.WaitGroup

    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for job := range jobs {
                select {
                case <-limiter.C:
                    // Rate limited
                case <-ctx.Done():
                    return
                }
                results <- process(job)
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

---

## errgroup

Use `golang.org/x/sync/errgroup` for coordinated goroutines with error handling.

### Basic Usage

```go
import "golang.org/x/sync/errgroup"

func fetchAll(ctx context.Context, urls []string) ([]Response, error) {
    g, ctx := errgroup.WithContext(ctx)
    responses := make([]Response, len(urls))

    for i, url := range urls {
        i, url := i, url  // Capture for goroutine
        g.Go(func() error {
            resp, err := fetch(ctx, url)
            if err != nil {
                return fmt.Errorf("fetching %s: %w", url, err)
            }
            responses[i] = resp
            return nil
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err  // First error cancels all
    }
    return responses, nil
}
```

### With Limit

```go
func processItems(ctx context.Context, items []Item) error {
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(10)  // Max 10 concurrent goroutines

    for _, item := range items {
        item := item
        g.Go(func() error {
            return processItem(ctx, item)
        })
    }

    return g.Wait()
}
```

---

## Context and Cancellation

### Creating Contexts

```go
// With timeout
ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
defer cancel()

// With deadline
ctx, cancel := context.WithDeadline(context.Background(), time.Now().Add(time.Hour))
defer cancel()

// With cancellation
ctx, cancel := context.WithCancel(context.Background())
defer cancel()

// With value (use sparingly)
ctx = context.WithValue(ctx, requestIDKey, requestID)
```

### Respecting Cancellation

```go
func longOperation(ctx context.Context) error {
    for i := 0; i < 1000; i++ {
        // Check cancellation periodically
        select {
        case <-ctx.Done():
            return ctx.Err()
        default:
        }

        // Do work
        if err := doStep(ctx, i); err != nil {
            return err
        }
    }
    return nil
}
```

### Propagating Context

```go
// Always pass context as first parameter
func (s *Service) GetUser(ctx context.Context, id string) (*User, error) {
    // Pass to downstream calls
    return s.repo.FindByID(ctx, id)
}
```

---

## Graceful Shutdown

### HTTP Server

```go
func main() {
    ctx, cancel := signal.NotifyContext(context.Background(),
        syscall.SIGINT, syscall.SIGTERM)
    defer cancel()

    srv := &http.Server{
        Addr:    ":8080",
        Handler: handler,
    }

    // Start server in goroutine
    go func() {
        if err := srv.ListenAndServe(); err != http.ErrServerClosed {
            log.Fatal(err)
        }
    }()

    log.Println("Server started")

    // Wait for shutdown signal
    <-ctx.Done()
    log.Println("Shutting down...")

    // Give outstanding requests time to complete
    shutdownCtx, shutdownCancel := context.WithTimeout(
        context.Background(), 30*time.Second)
    defer shutdownCancel()

    if err := srv.Shutdown(shutdownCtx); err != nil {
        log.Printf("Shutdown error: %v", err)
    }

    log.Println("Server stopped")
}
```

### Multiple Services

```go
func main() {
    ctx, cancel := signal.NotifyContext(context.Background(),
        syscall.SIGINT, syscall.SIGTERM)
    defer cancel()

    g, ctx := errgroup.WithContext(ctx)

    // HTTP server
    g.Go(func() error {
        return runHTTPServer(ctx)
    })

    // Background worker
    g.Go(func() error {
        return runWorker(ctx)
    })

    // Metrics server
    g.Go(func() error {
        return runMetricsServer(ctx)
    })

    if err := g.Wait(); err != nil {
        log.Printf("Shutdown: %v", err)
    }
}
```

---

## Sync Primitives

### sync.Mutex

```go
type SafeCounter struct {
    mu    sync.Mutex
    count int
}

func (c *SafeCounter) Inc() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.count++
}

func (c *SafeCounter) Value() int {
    c.mu.Lock()
    defer c.mu.Unlock()
    return c.count
}
```

### sync.RWMutex

```go
type Cache struct {
    mu    sync.RWMutex
    items map[string]Item
}

func (c *Cache) Get(key string) (Item, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    item, ok := c.items[key]
    return item, ok
}

func (c *Cache) Set(key string, item Item) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.items[key] = item
}
```

### sync.Once

```go
var (
    instance *Database
    once     sync.Once
)

func GetDB() *Database {
    once.Do(func() {
        instance = connectToDatabase()
    })
    return instance
}
```

### sync.WaitGroup

```go
func processAll(items []Item) {
    var wg sync.WaitGroup

    for _, item := range items {
        wg.Add(1)
        go func(item Item) {
            defer wg.Done()
            process(item)
        }(item)
    }

    wg.Wait()
}
```

---

## Common Mistakes

### Goroutine Leak

```go
// Bad: Goroutine never exits
go func() {
    for {
        ch <- data  // Blocks forever if no receiver
    }
}()

// Good: Respect context
go func(ctx context.Context) {
    for {
        select {
        case ch <- data:
        case <-ctx.Done():
            return
        }
    }
}(ctx)
```

### Data Race

```go
// Bad: Shared variable without sync
counter := 0
for i := 0; i < 1000; i++ {
    go func() {
        counter++  // DATA RACE
    }()
}

// Good: Use atomic or mutex
var counter atomic.Int64
for i := 0; i < 1000; i++ {
    go func() {
        counter.Add(1)
    }()
}
```

### Channel Not Closed

```go
// Bad: Receiver blocks forever
ch := make(chan int)
go func() {
    for i := 0; i < 10; i++ {
        ch <- i
    }
    // Forgot to close!
}()

for v := range ch {  // Blocks forever
    fmt.Println(v)
}

// Good: Always close when done sending
go func() {
    defer close(ch)
    for i := 0; i < 10; i++ {
        ch <- i
    }
}()
```

---

**Related Files:**
- [SKILL.md](../SKILL.md) - Main guide
- [error-handling.md](error-handling.md) - Error handling in concurrent code
- [performance.md](performance.md) - Performance optimization
