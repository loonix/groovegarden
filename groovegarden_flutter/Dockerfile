FROM cirrusci/flutter:stable

# Set the working directory inside the container
WORKDIR /frontend-app

# Copy the Flutter project files
COPY . .

# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos "" flutteruser
USER flutteruser

# Install Flutter dependencies
RUN flutter pub get

# Expose the Flutter web port
EXPOSE ${FLUTTER_PORT:-60387}

# Command to run the Flutter web server
CMD ["flutter", "run", "--web-port", "${FLUTTER_PORT:-60387}"]