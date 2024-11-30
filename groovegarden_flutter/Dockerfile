# Use a Flutter stable image
FROM cirrusci/flutter:stable

# Set the working directory
WORKDIR /frontent-app

# Copy Flutter project files
COPY . .

# Install dependencies
RUN flutter pub get

# Expose the Flutter app port
EXPOSE 60387

# Serve the Flutter web app
CMD ["flutter", "run", "--web-port", "60387", "--web-hostname", "0.0.0.0"]
