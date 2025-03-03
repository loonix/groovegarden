#!/bin/bash

PORT=54321

# Check if the port is in use
PID=$(lsof -t -i:$PORT)

if [ -n "$PID" ]; then
    echo "Port $PORT is in use by PID $PID. Killing the process..."
    kill -9 $PID
    sleep 1  # Give it a moment to release the port
fi

# Double-check port is free
PID=$(lsof -t -i:$PORT)
if [ -n "$PID" ]; then
    echo "Failed to free port $PORT. Please manually kill process $PID or use a different port."
    exit 1
fi

# Clear any old browser data that might be affecting redirects
echo "Note: If you're still having redirect issues, consider clearing your browser cache/cookies"

# Run the Flutter command with explicit port
echo "Starting Flutter web server on port $PORT..."
flutter run -d web-server --web-port=$PORT --web-hostname=localhost
