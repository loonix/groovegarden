FROM ghcr.io/cirruslabs/flutter:3.24.4

# Install CMake
RUN apt-get update && apt-get install -y cmake

# Set the working directory inside the container
WORKDIR /app

# Copy the Flutter project files
COPY . .

# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos "" flutteruser

# Ensure proper permissions for the project directory and Flutter SDK directory
RUN chown -R flutteruser:flutteruser /app /sdks/flutter

USER flutteruser

# Add the Flutter SDK directory to the list of safe directories in Git
RUN git config --global --add safe.directory /sdks/flutter

# Install Flutter dependencies
RUN flutter pub get

# Build for web
RUN flutter build web

# Expose the Flutter web port
EXPOSE ${FLUTTER_PORT:-54321}

# Run the server using the built web assets
CMD ["sh", "-c", "cd build/web && flutter run -d web-server --web-port=${FLUTTER_PORT:-54321} --web-hostname=0.0.0.0"]