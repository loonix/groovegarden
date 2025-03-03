# GrooveGarden

GrooveGarden is a radio-style music streaming platform where users can upload songs, vote for the next track to play, and enjoy synchronized music streaming. The application includes a backend server, a frontend Flutter app, and an Icecast streaming server.

---

## Features

- 🎵 **Music Streaming**: All users hear the same synchronized stream.
- 📤 **Song Uploads**: Artists can upload their music for streaming.
- 👍 **Voting System**: Listeners vote on the next track to play.
- 📡 **Streaming**: Powered by Icecast for seamless music delivery.
- 🔑 **Google OAuth Integration**: User authentication via Google.

---

## Tech Stack

- **Backend**: Go (`chi`, `godotenv`, `lib/pq`, `jwt`)
- **Frontend**: Flutter
- **Streaming**: Icecast
- **Database**: PostgreSQL
- **Containerization**: Docker

---

## Project Structure
```yaml
project-root/
│
├── config/
│   └── icecast.xml             # Configuration file for Icecast streaming server
│
├── groovegarden-backend/
│   ├── .env                    # Environment variables (GOOGLE_CLIENT_ID, SERVER_PORT, etc.)
│   ├── go.mod                  # Go module dependencies
│   ├── go.sum                  # Dependency checksums
│   ├── main.go                 # Entry point for the Go backend
│   ├── controllers/            # Backend controllers (song, streaming, auth, etc.)
│   ├── database/               # Database connection and initialization code
│   ├── middleware/             # Middleware (e.g., authentication, role checks)
│   ├── models/                 # Data models (e.g., User, Song)
│   ├── routes/                 # HTTP route definitions
│   └── uploads/                # Directory for uploaded songs
│
├── groovegarden_flutter/
│   ├── pubspec.yaml            # Flutter project configuration
│   ├── lib/                    # Flutter app source code
│   │   ├── main.dart           # Entry point for the Flutter app
│   │   ├── screens/            # Flutter app screens (Home, Login, Song Upload, etc.)
│   │   └── services/           # API and WebSocket services
│   └── assets/                 # Static assets for the Flutter app
│
├── docker-compose.yml          # Docker Compose file for the entire project
├── README.md                   # Project documentation (this file)
└── Dockerfile                  # Dockerfile for the Go backend
```

---

## Getting Started

### Prerequisites

- [Docker](https://www.docker.com/)
- [Flutter](https://flutter.dev/)
- PostgreSQL database

### Environment Variables

Create `.env` files in the following locations:

#### `groovegarden-backend/.env`
```env
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
REDIRECT_URL=http://localhost:8081/google/callback
SERVER_PORT=8081
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=your_db_user
POSTGRES_PASSWORD=your_db_password
POSTGRES_DB=groovegarden
```

## Run with Docker
### Build and Start Containers
Run the following command to start the entire stack:
```bash
docker-compose up --build
```

### Accessing the Application
- Frontend: http://localhost:60387
- Backend: http://localhost:8081
- Icecast Stream: http://localhost:9000/stream

## Development
### Backend
Navigate to the backend folder and run:

```bash
cd groovegarden-backend 
go run main.go
```
### Frontend
Ensure you have Flutter installed. Navigate to the `groovegarden_flutter` folder and run:

```bash
flutter run
```

### Database
Run PostgreSQL locally or connect to the containerized database. Use the `.sql` scripts to initialize the database schema.

## Contributing
1. Fork the repository.
2. Create a feature branch: git checkout -b feature-name.
3. Commit changes: git commit -m 'Add new feature'.
4. Push to the branch: git push origin feature-name.
5. Open a pull request.

## License
MIT License. See LICENSE for details.

Feel free to adapt this to your specific requirements or add more sections as needed!
