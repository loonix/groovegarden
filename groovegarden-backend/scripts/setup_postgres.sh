#!/bin/bash
# Script to help set up PostgreSQL for GrooveGarden

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}PostgreSQL Setup Helper for GrooveGarden${NC}"
echo "This script will help you set up PostgreSQL for use with GrooveGarden."

# Check if PostgreSQL is installed
echo -e "\n${YELLOW}Checking if PostgreSQL is installed...${NC}"
if command -v psql &> /dev/null; then
    echo -e "${GREEN}PostgreSQL is installed.${NC}"
    psql_version=$(psql --version)
    echo "PostgreSQL version: $psql_version"
else
    echo -e "${RED}PostgreSQL is not installed or not in PATH.${NC}"
    echo "Please install PostgreSQL with:"
    echo "  macOS:    brew install postgresql"
    echo "  Ubuntu:   sudo apt install postgresql"
    echo "  Windows:  Download from https://www.postgresql.org/download/windows/"
    exit 1
fi

# Get current username
current_user=$(whoami)
echo -e "\n${YELLOW}Detected current user:${NC} $current_user"

# Try to determine PostgreSQL superuser
echo -e "\n${YELLOW}Checking for PostgreSQL admin user...${NC}"

# Try with common PostgreSQL usernames
pg_users=("postgres" "$current_user")
pg_user_found=false

for user in "${pg_users[@]}"; do
    echo "Trying with user: $user"
    if psql -U "$user" -c "\du" postgres &> /dev/null; then
        pg_user_found=true
        echo -e "${GREEN}Successfully connected with user:${NC} $user"
        break
    fi
done

if [ "$pg_user_found" = false ]; then
    echo -e "${RED}Could not find a working PostgreSQL user.${NC}"
    echo "You'll need to manually update the database credentials in .env file."
else
    # Update .env file
    echo -e "\n${YELLOW}Updating .env file with working PostgreSQL settings...${NC}"
    sed -i '' "s/^POSTGRES_USER=.*/POSTGRES_USER=$user/" ../.env
    echo -e "${GREEN}Updated POSTGRES_USER in .env to:${NC} $user"
fi

# Try to create database
echo -e "\n${YELLOW}Attempting to create groovegarden database...${NC}"
if psql -U "$user" -c "CREATE DATABASE groovegarden" postgres &> /dev/null; then
    echo -e "${GREEN}Database 'groovegarden' created successfully.${NC}"
else
    echo -e "${YELLOW}Could not create database 'groovegarden'. It may already exist or there might be permission issues.${NC}"
    # Check if database exists
    if psql -U "$user" -lqt | cut -d \| -f 1 | grep -qw groovegarden; then
        echo -e "${GREEN}Database 'groovegarden' already exists.${NC}"
    else
        echo -e "${RED}Database 'groovegarden' doesn't exist and couldn't be created.${NC}"
        echo "You may need to create it manually with: createdb groovegarden"
    fi
fi

echo -e "\n${GREEN}Setup complete!${NC}"
echo "You should now update your .env file with the correct PostgreSQL credentials if needed."
echo "Then restart the server with: ./start_server.sh"
