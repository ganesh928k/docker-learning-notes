# 18 — Multi-Stage Builds

One of the most powerful features of Docker is the **multi-stage build**. It allows you to use multiple `FROM` statements in a single Dockerfile, significantly reducing the final size of your Docker images.

---

## The Problem

When you build an application (like Go, Java, or C++), you need compilers, SDKs, and build tools. However, once the application is compiled into an executable binary, you **do not need** the compilers to run it.

If you leave the build tools in your final image, your image becomes bloated (often 1GB+) and has a larger surface area for security vulnerabilities.

---

## The Solution: Multi-Stage Builds

You can split your Dockerfile into "stages". 
1. **Stage 1 (Builder):** Uses a heavy base image with all the build tools to compile the application.
2. **Stage 2 (Production):** Uses a tiny, lightweight base image (like `alpine` or `scratch`). It only copies the finished binary from Stage 1.

---

## Example: Go Application (`main.go`)

### The Code (`main.go`)
```go
package main

import "fmt"

func main() {
    fmt.Println("Hello, Docker Multistage Build!")
}
```

### The Multi-Stage Dockerfile

```dockerfile
# ==========================================
# STAGE 1: Build the Application
# ==========================================
FROM golang:1.20 AS builder

WORKDIR /app

# Copy source code
COPY main.go .

# Compile the application into a binary named 'myapp'
# CGO_ENABLED=0 creates a statically linked binary (perfect for scratch containers)
RUN CGO_ENABLED=0 GOOS=linux go build -o myapp main.go

# ==========================================
# STAGE 2: Create the Final Lightweight Image
# ==========================================
# 'scratch' is a special empty image. It has 0 MB!
FROM scratch

# Copy ONLY the compiled binary from the 'builder' stage
COPY --from=builder /app/myapp /myapp

# Run the binary
CMD ["/myapp"]
```

---

## Benefits

1. **Tiny Images**: The final image size for the Go app above will be ~2MB instead of ~800MB (the size of the `golang` image).
2. **More Secure**: Without shells, package managers, or compilers in the final image, attackers have a much harder time exploiting the container.
3. **Cleaner Dockerfiles**: You don't need complex `RUN apt-get remove && apt-get clean` chaining tricks to shrink your images.
