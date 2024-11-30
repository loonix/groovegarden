# Use the latest Go image
FROM golang:1.20

# Set the working directory inside the container
WORKDIR /app

# Set Go proxy (optional if behind a firewall or proxy)
ENV GOPROXY=https://proxy.golang.org

# Copy go.mod and go.sum first (if they exist)
COPY go.mod go.sum ./

# Run go mod download with verbose output
RUN go mod download -v

# Now copy the rest of the Go source code
COPY . .

# Build the Go binary
RUN go build -o main .

# Expose the backend port (default 8081 if not set)
EXPOSE ${SERVER_PORT:-8081}

# Run the backend when the container starts
CMD ["./main"]
