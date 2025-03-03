# Use a Go image
FROM golang:1.20

# Set the working directory inside the container
WORKDIR /app

# Copy go.mod and go.sum first to take advantage of Docker cache
COPY go.mod go.sum ./

# Install dependencies (this will download and cache them)
RUN go mod download

# Now copy the rest of the Go source files
COPY . .

# Create uploads directory
RUN mkdir -p /app/uploads && chmod 777 /app/uploads

# Build the Go binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# Expose the backend port (default 8081 if not set)
EXPOSE ${SERVER_PORT:-8081}

# Run the backend when the container starts
CMD ["./main"]
