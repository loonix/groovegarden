# Use a Go image
FROM golang:1.20

# Set the working directory inside the container
WORKDIR /app

# Copy go.mod and go.sum first (if they exist)
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Now copy the rest of the Go source code
COPY . .

# Build the Go binary (main.go should be in the root of the context)
RUN go build -o main .

# Expose the backend port (use default value if not set)
EXPOSE ${SERVER_PORT:-8081}

# Run the backend when the container starts
CMD ["./main"]
