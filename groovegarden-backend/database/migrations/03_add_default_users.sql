-- Ensure users table structure is correct
ALTER TABLE users
ADD COLUMN IF NOT EXISTS profile_picture TEXT,
ADD COLUMN IF NOT EXISTS bio TEXT,
ADD COLUMN IF NOT EXISTS links JSONB,
ADD COLUMN IF NOT EXISTS music_preferences JSONB,
ADD COLUMN IF NOT EXISTS location TEXT,
ADD COLUMN IF NOT EXISTS date_of_birth TEXT,
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP DEFAULT NOW();

-- Insert default user if not exists
INSERT INTO users (id, name, email, account_type)
VALUES 
    (1, 'Admin User', 'admin@groovegarden.com', 'admin'),
    (2, 'Artist User', 'artist@groovegarden.com', 'artist'),
    (3, 'Listener User', 'listener@groovegarden.com', 'listener')
ON CONFLICT (id) DO NOTHING;
