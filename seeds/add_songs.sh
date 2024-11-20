#!/bin/bash

curl -X POST -H "Content-Type: application/json" \
-d '{"title": "Song A", "url": "https://example.com/songA.mp3"}' \
http://localhost:8081/add

curl -X POST -H "Content-Type: application/json" \
-d '{"title": "Song B", "url": "https://example.com/songB.mp3"}' \
http://localhost:8081/add
