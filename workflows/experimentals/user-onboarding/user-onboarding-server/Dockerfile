# Use the official Go image as a builder
FROM golang:1.21 AS builder

WORKDIR /app

# Copy the Go module files and download dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the application code
COPY . .

# Build the Go binary
RUN CGO_ENABLED=0 go build -o user-onboarding .

# Use a minimal base image for the final container
FROM alpine:latest

WORKDIR /app

# Copy the compiled binary from the builder stage
COPY --from=builder /app/user-onboarding /app/user-onboarding

# Expose the port the server listens on
EXPOSE 8080

# Start the application
CMD ["/app/user-onboarding"]
