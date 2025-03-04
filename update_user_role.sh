#!/bin/bash

# Default values
DATABASE="groovegarden"
USER="grooveuser"
PASSWORD="groovepass" 
HOST="localhost"
PORT="5432"
EMAIL="$1"
ROLE="$2"

if [ -z "$EMAIL" ] || [ -z "$ROLE" ]; then
  echo "Usage: $0 <email> <role>"
  echo "Example: $0 user@example.com artist"
  exit 1
fi

# SQL to update user role
SQL_COMMAND="UPDATE users SET account_type = '$ROLE' WHERE email = '$EMAIL';"

echo "Updating user $EMAIL to $ROLE role..."
echo "$SQL_COMMAND" | PGPASSWORD="$PASSWORD" psql -h "$HOST" -p "$PORT" -U "$USER" -d "$DATABASE"

if [ $? -eq 0 ]; then
  echo "User role updated successfully. You'll need to log out and log back in for changes to take effect."
else 
  echo "Failed to update user role."
  exit 1
fi
