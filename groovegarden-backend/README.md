# Groove Garden Backend

## Database Setup

Follow these steps to set up the PostgreSQL database required for the application:

### Prerequisites

- PostgreSQL installed on your system
- `psql` command line tool available

### Setup Steps

1. Create the database:
   ```bash
   createdb groovegarden
   ```

2. Create the user role:
   ```bash
   psql -d groovegarden -c "CREATE ROLE grooveuser WITH PASSWORD 'groovepass';"
   ```

3. Enable login permission for the user:
   ```bash
   psql -d groovegarden -c "ALTER ROLE grooveuser WITH LOGIN;"
   ```

4. Grant necessary permissions to the user:
   ```bash
   psql -d groovegarden -c "GRANT ALL PRIVILEGES ON SCHEMA public TO grooveuser;"
   ```

5. To verify your setup, run the application:
   ```bash
   go run main.go
   ```
   
   You should see: "Database connected!" and "Table 'songs' ensured to exist"

### Troubleshooting

- **Error: "role grooveuser does not exist"** - Make sure you've created the role as shown in step 2.
- **Error: "role grooveuser is not permitted to log in"** - Ensure you've completed step 3.
- **Error: "permission denied for schema public"** - Check that you've granted permissions as in step 4.
- **Connection issues** - Verify PostgreSQL is running and listening on the default port (5432).

## Running the Application

```bash
go run main.go
```

## Using pgAdmin to Manage the Database

pgAdmin is a popular graphical interface for PostgreSQL database management.

### Installation

1. Download and install pgAdmin from the [official website](https://www.pgadmin.org/download/).

### Connecting to the Database

1. Launch pgAdmin.
2. Right-click on "Servers" in the left panel and select "Create" > "Server...".
3. In the "General" tab, enter a name for your connection (e.g., "GrooveGarden").
4. In the "Connection" tab, enter the following details:
   - Host name/address: `localhost`
   - Port: `5432`
   - Maintenance database: `groovegarden`
   - Username: `grooveuser`
   - Password: `groovepass`
   - Save password: Check this box if desired
5. Click "Save" to connect.

### Exploring the Database

Once connected:
1. Navigate through: Servers > GrooveGarden > Databases > groovegarden > Schemas > public > Tables
2. Right-click on the "songs" table and select "View/Edit Data" > "All Rows" to see the data.
3. You can run SQL queries using the Query Tool (Tools > Query Tool or press F3).

### Common Tasks in pgAdmin

- **Add Data**: Right-click on a table > "View/Edit Data" > "All Rows", then use the interface to add records.
- **Modify Schema**: Right-click on a table > "Properties" to view and edit the table structure.
- **Run SQL Queries**: Use the Query Tool to execute custom SQL commands.
- **Backup Database**: Right-click on the database > "Backup..." to create a database dump.

## API Endpoints

http://localhost:8081/oauth/login

icecast -c /usr/local/etc/icecast.xml

curl -X POST http://localhost:8081/stream/start
curl -X POST http://localhost:8081/stream/stop