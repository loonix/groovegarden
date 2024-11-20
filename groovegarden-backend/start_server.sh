#!/bin/bash

PORT=8081

# Find the PID of the process using the port
PID=$(lsof -t -i:$PORT)

if [ ! -z "$PID" ]; then
  echo "Port $PORT is in use by PID $PID. Killing the process..."
  kill -9 $PID
  echo "Process $PID killed. Starting server..."
else
  echo "Port $PORT is free. Starting server..."
fi

# Start the Go server
go run main.go
