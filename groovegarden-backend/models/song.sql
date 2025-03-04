CREATE TABLE IF NOT EXISTS songs (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    duration INTEGER NOT NULL,  -- Duration in seconds
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    votes INTEGER DEFAULT 0,
    storage_path VARCHAR(255) NOT NULL,  -- Path where the song file is stored
    artist_id INTEGER REFERENCES users(id) ON DELETE SET NULL
);
