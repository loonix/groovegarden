FROM cirrusci/flutter:3.5.0

# Set the working directory inside the container
WORKDIR /frontend-app

# Copy the Flutter project files
COPY . .

# Install Flutter dependencies
RUN flutter pub get

# Expose the Flutter web port
EXPOSE ${FLUTTER_PORT:-60387}

# Command to run the Flutter web server
CMD ["flutter", "run", "--web-port", "${FLUTTER_PORT:-60387}"]