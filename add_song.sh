#!/bin/bash

# Set the API base URL
API_URL="http://localhost:8081"

echo "Generating authentication token..."
TOKEN=$(curl -s $API_URL/generate-token)

# Check if token was retrieved successfully
if [ -z "$TOKEN" ]; then
  echo "Failed to retrieve token. Make sure the server is running."
  exit 1
fi

echo "Token received: ${TOKEN:0:15}..."

# Create a sample song payload
SONG_DATA='{
  "title": "Sample Song",
  "artist": "Sample Artist",
  "url": "https://example.com/sample.mp3"
}'

echo "Adding song to the system..."
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "$SONG_DATA" \
  $API_URL/songs/add

echo -e "\nDone!"
