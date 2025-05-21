# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o workload .

# Final stage
FROM alpine:3.21

# Create a non-root user
RUN adduser -D -g '' appuser

WORKDIR /app

# Copy the binary from builder
COPY --from=builder /app/workload .

# Use non-root user
USER appuser

# Expose the metrics port
EXPOSE 2112

# Run the application
CMD ["./workload"]
