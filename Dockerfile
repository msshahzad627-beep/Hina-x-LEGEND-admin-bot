# Stage 1: Build
FROM debian:bookworm-slim AS build-env

RUN apt-get update && apt-get install -y curl git unzip xz-utils libglu1-mesa ca-certificates

RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN git config --global --add safe.directory /flutter
RUN flutter config --no-analytics
RUN flutter config --enable-web

WORKDIR /app
COPY . .

RUN flutter pub get

# Create web platform files without touching lib/
RUN flutter create --platforms web .

RUN flutter build web --release

# Stage 2: Serve
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
