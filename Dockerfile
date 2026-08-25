# ---- Build stage: compile Flutter Web admin ----
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Copy only the Flutter app
COPY mobile_app/ ./

# Install dependencies
RUN flutter pub get

# Build the web entry point.
# API_BASE_URL is baked at compile time. The default matches the backend
# service name defined in render.yaml ("yarmouk-backend").
ARG API_BASE_URL=https://yarmouk-backend.onrender.com/v1
RUN flutter build web -t lib/main_web.dart \
    --dart-define=API_BASE_URL=$API_BASE_URL \
    --release

# ---- Serve stage: nginx ----
FROM nginx:alpine AS serve
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
