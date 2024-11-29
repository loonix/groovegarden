# Use a Go image
FROM golang:1.20

# Set the working directory
WORKDIR /app

# Copy Go source files
COPY . .

# Install dependencies and build
RUN go mod download
RUN go build -o main .

# Expose the backend port
EXPOSE ${SERVER_PORT:-8081}

# Run the backend
CMD ["./main"]
