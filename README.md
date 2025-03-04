# GrooveGarden

GrooveGarden is a radio-style music streaming platform where users can upload songs, vote for the next track to play, and enjoy synchronized music streaming. The application includes a Go backend server, a Flutter web frontend, and an Icecast streaming server.

---

## Features

- 🎵 **Music Streaming**: All users hear the same synchronized stream.
- 📤 **Song Uploads**: Artists can upload their music for streaming.
- 👍 **Voting System**: Listeners vote on the next track to play.
- 📡 **Streaming**: Powered by Icecast for seamless music delivery.
- 🔑 **Google OAuth Integration**: User authentication via Google.

---

## Tech Stack

- **Backend**: Go with Chi router
- **Frontend**: Flutter Web
- **Authentication**: Google OAuth 2.0 + JWT
- **Streaming**: Icecast
- **Database**: PostgreSQL
- **Real-time Communication**: WebSockets
- **Containerization**: Docker & Docker Compose

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

- [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/)
- [Go](https://golang.org/) (1.20 or later)
- [Flutter](https://flutter.dev/) (3.24 or later)
- [PostgreSQL](https://www.postgresql.org/) database

### Environment Setup

1. Set up a Google OAuth application in the [Google Cloud Console](https://console.cloud.google.com/)
2. Create `.env` files as described below

#### `groovegarden-backend/.env`

```env
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
REDIRECT_URL=http://localhost:8081/google/callback
SERVER_PORT=8081
FRONTEND_URL=http://localhost:54321
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=your_db_user
POSTGRES_PASSWORD=your_db_password
POSTGRES_DB=groovegarden
```

#### Project Root `.env` (for Docker Compose)

```env
SERVER_PORT=8081
FLUTTER_PORT=54321
ICECAST_PORT=9000
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
```

---

## Development and Testing

### Utility Scripts

The project includes several utility scripts to make development and testing easier:

#### Running the Flutter Web App

```bash
cd groovegarden_flutter
./run_web.sh
```

This script checks if the specified port (54321) is in use, clears it if necessary, and then starts the Flutter web app.

#### Setting Up Test Data

You can quickly populate your database with test songs using the `setup_test_data.sh` script:

```bash
./setup_test_data.sh <jwt_token>
```

Replace `<jwt_token>` with a valid JWT token from your application. This script:
1. Creates test song files in the uploads directory
2. Inserts song metadata directly into the database
3. Sets initial vote counts for testing

#### Updating User Role

To change a user's role (e.g., from listener to artist):

```bash
./update_user_role.sh <email> <role>
```

Replace `<email>` with the user's email and `<role>` with either "artist" or "listener". For example:

```bash
./update_user_role.sh user@example.com artist
```

**Note**: After changing a user's role, you need to log out and log back in for the changes to take effect.

---

## Deployment

### Docker Deployment

Build and start all services with Docker Compose:

```bash
docker-compose up --build
```

This will start:
- Backend Go server
- Flutter web frontend
- Icecast streaming server

### Manual Deployment

#### Backend

```bash
cd groovegarden-backend
go mod download
go build -o main .
./main
```

#### Frontend

```bash
cd groovegarden_flutter
flutter pub get
./run_web.sh
```

---

## Accessing the Application

- **Frontend**: http://localhost:54321
- **Backend API**: http://localhost:8081
- **Icecast Stream**: http://localhost:9000/stream

---

## Development Notes

- The application uses WebSockets for real-time vote count updates
- Cross-tab communication is implemented using localStorage events
- CORS is configured to allow requests from the Flutter app origin
- JWT authentication middleware protects sensitive endpoints
- Role-based access controls restrict artist-only features

---

## Troubleshooting

### No Songs Appearing in the UI

If you don't see any songs in the app:
1. Check if the database is properly initialized with `InitializeDatabase()`
2. Run the `setup_test_data.sh` script to add test data
3. Check the browser console for any API errors
4. Verify that your JWT token is valid and has the appropriate permissions

### Permission Issues with Song Upload

If you're unable to upload songs as an artist:
1. Verify your account has the "artist" role using `update_user_role.sh`
2. Make sure you're using a fresh JWT token after role changes
3. Check server logs for any permission or validation errors

### Database Connectivity Issues

For database connection problems:
1. Make sure PostgreSQL is running and accessible
2. Check environment variables are correctly set for database connection
3. Verify the database schema is created with all required tables and columns

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -m 'Add new feature'`
4. Push to the branch: `git push origin feature-name`
5. Open a pull request

---

## License

MIT License. See LICENSE for details.
