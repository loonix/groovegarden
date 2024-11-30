# Use a Go image
FROM golang:1.20

# Set the working directory inside the container
WORKDIR /app

# Copy go.mod and go.sum first to take advantage of Docker cache
COPY go.mod go.sum ./

# Install dependencies (this will download and cache them)
RUN go mod download -x  # Verbose output for debugging

# Now copy the rest of the Go source files
COPY . .

# Build the Go binary
RUN go build -o main .

# Expose the backend port (default 8081 if not set)
EXPOSE ${SERVER_PORT:-8081}

# Run the backend when the container starts
CMD ["./main"]
