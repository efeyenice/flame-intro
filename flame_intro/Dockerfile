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

# Copy pubspec files first for caching dependencies
COPY pubspec.* ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the application code
COPY . .

# Get dependencies offline
RUN flutter pub get --offline

# Build the web app in release mode
RUN flutter build web --release

# Runtime stage
FROM nginx:stable-alpine

# Copy the built web files from the builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Run nginx
CMD ["nginx", "-g", "daemon off;"] 