# Build stage
FROM cirrusci/flutter:stable AS builder

# Install dependencies required for Flutter
RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa

# Clone Flutter stable channel
RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 /usr/local/flutter

# Set Flutter path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor to verify installation
RUN flutter doctor

# Set working directory
WORKDIR /app

# Accept API_URL as build argument
ARG API_URL=http://localhost:8000
ENV API_URL=$API_URL

# Copy pubspec files first for caching dependencies
COPY pubspec.* ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the application code
COPY . .

# Get dependencies offline
RUN flutter pub get --offline

# Build the web app in release mode with API_URL
RUN flutter build web --release --dart-define=API_URL=$API_URL

# Create a simple config file for runtime (backup approach)
RUN echo "window.API_URL = '$API_URL';" > /app/build/web/config.js

# Runtime stage
FROM nginx:stable-alpine

# Copy the built web files from the builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Run nginx
CMD ["nginx", "-g", "daemon off;"] 