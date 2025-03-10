#!/bin/bash
# Script to safely remove the deprecated db.go file
# Make this script executable with: chmod +x cleanup_db_files.sh

DB_FILE="../database/db.go"

# Check if file exists
if [ -f "$DB_FILE" ]; then
  # Create a backup
  cp "$DB_FILE" "${DB_FILE}.bak"
  echo "Created backup of $DB_FILE at ${DB_FILE}.bak"
  
  # Remove the file
  rm "$DB_FILE"
  echo "Removed $DB_FILE successfully"
  echo "All database connection functionality is now consolidated in database.go"
else
  echo "File $DB_FILE not found - cleanup already done!"
fi
