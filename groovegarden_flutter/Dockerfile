FROM cirrusci/flutter:3.5.0

# Set the working directory inside the container
WORKDIR /frontend-app

# Copy the Flutter project files
COPY . .

# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos "" flutteruser

# Ensure proper permissions for the Flutter SDK directory
RUN chown -R flutteruser:flutteruser /sdks/flutter

USER flutteruser

# Add the Flutter SDK directory to the list of safe directories in Git
RUN git config --global --add safe.directory /sdks/flutter

# Install Flutter dependencies
RUN flutter pub get

# Expose the Flutter web port
EXPOSE ${FLUTTER_PORT:-60387}

# Command to run the Flutter web server
CMD ["flutter", "run", "--web-port", "${FLUTTER_PORT:-60387}"]