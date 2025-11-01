# Multi-stage Dockerfile for building and serving the Flutter web app
#
# Stage 1 - build the web app using the official Flutter SDK image
# Stage 2 - serve the compiled static assets with nginx
#
# Notes:
# - This Dockerfile targets Flutter web. If you want to build mobile
#   (Android/iOS) artifacts, you'll need a different CI runner (macOS
#   for iOS) or Android SDK setup and cannot serve with nginx.
# - For CI systems, consider caching the Flutter SDK and pub cache for speed.

############################################
# Stage 1: Build Flutter web
############################################
FROM cirrusci/flutter:latest as builder

# Set working directory
WORKDIR /app

# Copy pubspec first to leverage Docker layer caching for dependencies
COPY pubspec.* ./
COPY pubspec.lock ./

# Get dependencies (uses cache layer when pubspec.* hasn't changed)
RUN flutter pub get --offline || flutter pub get

# Copy the rest of the source code
COPY . .

# Ensure Flutter tools are ready
RUN flutter doctor -v

# Build the web release
RUN flutter build web --release


############################################
# Stage 2: Serve with nginx
############################################
FROM nginx:stable-alpine

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy built web output from the builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Provide a basic nginx config (optional: you can mount your own config)
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]

# End of Dockerfile
