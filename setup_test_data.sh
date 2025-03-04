#!/bin/bash
# filepath: /Users/danielcarneiro/Development/Projects/groovegarden/setup_test_data.sh

echo "Setting up test data for GrooveGarden..."

# Get the JWT token (you would need to replace this with your actual token)
TOKEN="$1"
if [ -z "$TOKEN" ]; then
  echo "Please provide a JWT token as the first argument"
  exit 1
fi

# Create test directory for songs if it doesn't exist
mkdir -p ./groovegarden-backend/uploads

# Create a simple dummy MP3 file with zero bytes (just for testing)
touch ./groovegarden-backend/uploads/test_song.mp3

# Add test song directly to the database
echo "Adding test songs directly to the database..."

# Connect to PostgreSQL database using psql
DATABASE="groovegarden"
USER="grooveuser"
PASSWORD="groovepass"
HOST="localhost"
PORT="5432"

# Define SQL commands to insert test songs
SQL_COMMANDS=$(cat <<EOF
-- Insert some test songs
INSERT INTO songs (title, artist, duration, upload_date, votes, storage_path)
VALUES 
  ('Summer Vibes', 'DJ Example', 210, CURRENT_TIMESTAMP, 5, './uploads/test_song.mp3'),
  ('Beats and Dreams', 'Cool Artist', 180, CURRENT_TIMESTAMP, 3, './uploads/test_song.mp3'),
  ('Electronic Journey', 'Future Sounds', 240, CURRENT_TIMESTAMP, 7, './uploads/test_song.mp3');
EOF
)

# Execute SQL commands
echo "$SQL_COMMANDS" | PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DATABASE"

if [ $? -eq 0 ]; then
  echo "Test songs added successfully to the database."
else
  echo "Failed to add test songs to the database."
  exit 1
fi

echo "Done! You should now see songs in the app. Refresh your browser to see the changes."