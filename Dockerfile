# syntax=docker/dockerfile:1.7

FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Cache pub dependencies first for better layer reuse.
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Copy the rest of the Flutter web app and build a release bundle.
COPY . .

# CI repositories usually do not store .env. Create a fallback file so
# Flutter asset bundling does not fail when .env is listed in pubspec assets.
RUN if [ ! -f .env ]; then cp .env.example .env 2>/dev/null || touch .env; fi
RUN flutter build web --release --tree-shake-icons

FROM nginx:1.27-alpine AS runtime

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
