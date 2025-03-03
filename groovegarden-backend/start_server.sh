#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

PORT=${SERVER_PORT:-8081}
ICECAST_PORT=9000

# Find the PID of the process using the Go server port
PID=$(lsof -t -i:$PORT)

# Find the PID of the process using the Icecast port
ICECAST_PID=$(lsof -t -i:$ICECAST_PORT)

if [ ! -z "$PID" ]; then
  echo "Port $PORT is in use by PID $PID. Killing the process..."
  kill -9 $PID
  echo "Process $PID killed."
else
  echo "Port $PORT is free."
fi

if [ ! -z "$ICECAST_PID" ]; then
  echo "Icecast port $ICECAST_PORT is in use by PID $ICECAST_PID. Killing the process..."
  kill -9 $ICECAST_PID
  echo "Process $ICECAST_PID killed."
else
  echo "Icecast port $ICECAST_PORT is free."
fi

echo "Starting Icecast server..."
icecast -c /usr/local/etc/icecast.xml -b &
echo "Icecast started in background."

echo "Starting Go server..."
# Start the Go server
go run main.go
