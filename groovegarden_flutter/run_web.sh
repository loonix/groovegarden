#!/bin/bash

PORT=60387

# Check if the port is in use
PID=$(lsof -t -i:$PORT)

if [ -n "$PID" ]; then
    echo "Port $PORT is in use by PID $PID. Killing the process..."
    kill -9 $PID
fi

# Run the Flutter command
flutter run -d web-server --web-port=$PORT
