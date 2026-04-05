# syntax=docker/dockerfile:1.7

FROM ghcr.io/cirruslabs/flutter:stable AS base
WORKDIR /app

# Cache pub dependencies first for better layer reuse.
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

# Copy the rest of the Flutter web app and build a release bundle.
COPY . .

# CI repositories usually do not store .env. Create a fallback file so
# Flutter asset bundling does not fail when .env is listed in pubspec assets.
RUN if [ ! -f .env ]; then cp .env.example .env 2>/dev/null || touch .env; fi

FROM base AS unit-tests
RUN flutter test test

FROM base AS integration-tests
RUN if [ -d integration_test ] && find integration_test -name '*_test.dart' | grep -q .; then \
			flutter test integration_test; \
		else \
			echo "No integration tests found. Running web integration smoke build."; \
			flutter build web --release --tree-shake-icons --no-wasm-dry-run; \
		fi

FROM base AS build
# API_BASE_URL et API_PATH_PREFIX sont injectés au moment du build Dart (String.fromEnvironment).
# Valeurs par défaut : Railway backend sans préfixe /api.
ARG API_BASE_URL=https://backendagentai-production.up.railway.app
ARG API_PATH_PREFIX=
RUN flutter build web --release --tree-shake-icons --no-wasm-dry-run \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=API_PATH_PREFIX=${API_PATH_PREFIX}

FROM nginx:1.27-alpine AS runtime

# Patch base OS packages to reduce known critical vulnerabilities
# reported by image scanners (openssl/libxml2 stack).
RUN apk update && apk upgrade --no-cache && apk add --no-cache libxml2 openssl

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
