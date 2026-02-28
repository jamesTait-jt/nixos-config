# Performance Optimization in Go

Guide to writing efficient Go code.

## Table of Contents

- [Memory Optimization](#memory-optimization)
- [sync.Pool](#syncpool)
- [String Handling](#string-handling)
- [Slice Optimization](#slice-optimization)
- [Profiling](#profiling)
- [Common Pitfalls](#common-pitfalls)

---

## Memory Optimization

### Preallocate Slices

```go
// Bad: Multiple allocations as slice grows
func collectIDs(users []User) []string {
    var ids []string  // Starts at cap 0
    for _, u := range users {
        ids = append(ids, u.ID)  // May reallocate
    }
    return ids
}

// Good: Single allocation
func collectIDs(users []User) []string {
    ids := make([]string, 0, len(users))  // Preallocate
    for _, u := range users {
        ids = append(ids, u.ID)
    }
    return ids
}
```

### Preallocate Maps

```go
// Bad: Map grows dynamically
userMap := make(map[string]*User)

// Good: Preallocate if size known
userMap := make(map[string]*User, len(users))
```

### Avoid Unnecessary Allocations

```go
// Bad: Allocates new slice every call
func getBuffer() []byte {
    return make([]byte, 1024)
}

// Good: Reuse buffer
var bufferPool = sync.Pool{
    New: func() any {
        return make([]byte, 1024)
    },
}

func getBuffer() []byte {
    return bufferPool.Get().([]byte)
}

func putBuffer(b []byte) {
    bufferPool.Put(b)
}
```

### Pass by Pointer for Large Structs

```go
// Bad: Copies entire struct
func processLarge(data LargeStruct) { }

// Good: Pass pointer
func processLarge(data *LargeStruct) { }
```

---

## sync.Pool

For frequently allocated and short-lived objects.

### Basic Usage

```go
var bufferPool = sync.Pool{
    New: func() any {
        return new(bytes.Buffer)
    },
}

func process() {
    buf := bufferPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        bufferPool.Put(buf)
    }()

    // Use buffer
    buf.WriteString("data")
}
```

### Slice Pool

```go
var slicePool = sync.Pool{
    New: func() any {
        s := make([]byte, 0, 4096)
        return &s
    },
}

func getSlice() *[]byte {
    return slicePool.Get().(*[]byte)
}

func putSlice(s *[]byte) {
    *s = (*s)[:0]  // Reset length, keep capacity
    slicePool.Put(s)
}
```

### When to Use sync.Pool

- High-frequency allocations
- Objects with expensive initialization
- Known size/capacity objects
- Short-lived objects (may be GC'd between uses)

### When NOT to Use

- Long-lived objects
- Objects with complex state
- When allocation is infrequent

---

## String Handling

### Use strings.Builder

```go
// Bad: O(n²) allocations
func join(parts []string) string {
    result := ""
    for _, p := range parts {
        result += p  // New allocation each time
    }
    return result
}

// Good: O(n) with Builder
func join(parts []string) string {
    var b strings.Builder
    for _, p := range parts {
        b.WriteString(p)
    }
    return b.String()
}

// Good: With size hint
func join(parts []string) string {
    total := 0
    for _, p := range parts {
        total += len(p)
    }

    var b strings.Builder
    b.Grow(total)  // Preallocate
    for _, p := range parts {
        b.WriteString(p)
    }
    return b.String()
}
```

### Avoid string ↔ []byte Conversions

```go
// Bad: Converts twice
func process(s string) string {
    b := []byte(s)       // Allocation
    // modify b
    return string(b)     // Allocation
}

// Good: Work with bytes if possible
func process(b []byte) []byte {
    // modify b
    return b
}
```

### String Interning for Repeated Values

```go
var internPool = sync.Map{}

func intern(s string) string {
    if v, ok := internPool.Load(s); ok {
        return v.(string)
    }
    internPool.Store(s, s)
    return s
}
```

---

## Slice Optimization

### Avoid Memory Leaks with Slicing

```go
// Bad: Holds reference to entire backing array
func getPrefix(data []byte) []byte {
    return data[:10]  // Still references all of data
}

// Good: Copy to release backing array
func getPrefix(data []byte) []byte {
    result := make([]byte, 10)
    copy(result, data[:10])
    return result
}
```

### Reuse Slice Capacity

```go
// Reuse underlying array
func processMultiple(items []Item) {
    buffer := make([]byte, 0, 1024)

    for _, item := range items {
        buffer = buffer[:0]  // Reset length, keep capacity
        buffer = append(buffer, item.Data...)
        send(buffer)
    }
}
```

### Avoid Append in Hot Paths

```go
// Bad: May reallocate
func hot(data []int, value int) []int {
    return append(data, value)
}

// Good: Ensure capacity before hot path
func prepare(expected int) []int {
    return make([]int, 0, expected)
}
```

---

## Profiling

### CPU Profiling

```go
import "runtime/pprof"

func main() {
    f, _ := os.Create("cpu.prof")
    pprof.StartCPUProfile(f)
    defer pprof.StopCPUProfile()

    // Run application
}
```

Analyze: `go tool pprof cpu.prof`

### Memory Profiling

```go
import "runtime/pprof"

func main() {
    // Run application

    f, _ := os.Create("mem.prof")
    pprof.WriteHeapProfile(f)
    f.Close()
}
```

### HTTP Profiling Server

```go
import _ "net/http/pprof"

func main() {
    go func() {
        http.ListenAndServe("localhost:6060", nil)
    }()

    // Application code
}
```

Access at:
- `http://localhost:6060/debug/pprof/`
- `go tool pprof http://localhost:6060/debug/pprof/heap`

### Benchmark Memory

```bash
go test -bench=. -benchmem -memprofile=mem.prof
go tool pprof mem.prof
```

### Trace

```go
import "runtime/trace"

func main() {
    f, _ := os.Create("trace.out")
    trace.Start(f)
    defer trace.Stop()

    // Application code
}
```

Analyze: `go tool trace trace.out`

---

## Common Pitfalls

### Interface Boxing

```go
// Bad: Allocates for interface boxing
func process(values []int) {
    for _, v := range values {
        fmt.Println(v)  // v boxed to interface{}
    }
}

// Better: Batch formatting
func process(values []int) {
    fmt.Println(values)  // Single interface boxing
}
```

### Deferred Function Calls in Loops

```go
// Bad: Defers accumulate
func processFiles(paths []string) error {
    for _, path := range paths {
        f, err := os.Open(path)
        if err != nil {
            return err
        }
        defer f.Close()  // Accumulates!

        // process file
    }
    return nil
}

// Good: Close in loop
func processFiles(paths []string) error {
    for _, path := range paths {
        if err := processFile(path); err != nil {
            return err
        }
    }
    return nil
}

func processFile(path string) error {
    f, err := os.Open(path)
    if err != nil {
        return err
    }
    defer f.Close()

    // process file
    return nil
}
```

### Time Parsing

```go
// Bad: Parse layout every time
func parseDate(s string) (time.Time, error) {
    return time.Parse("2006-01-02", s)
}

// Good: Use constant layout
const dateLayout = "2006-01-02"

func parseDate(s string) (time.Time, error) {
    return time.Parse(dateLayout, s)
}
```

### Regexp Compilation

```go
// Bad: Compiles every call
func match(s string) bool {
    re := regexp.MustCompile(`\d+`)
    return re.MatchString(s)
}

// Good: Compile once
var digitRegex = regexp.MustCompile(`\d+`)

func match(s string) bool {
    return digitRegex.MatchString(s)
}
```

---

**Related Files:**
- [SKILL.md](../SKILL.md) - Main guide
- [testing.md](testing.md) - Benchmarking
- [concurrency.md](concurrency.md) - sync.Pool usage
