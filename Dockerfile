# Stage 1: Build Stage
FROM debian:bookworm-slim AS build-env

# 🛠️ ضروری ٹولز اور سیکیورٹی سرٹیفکیٹس (ca-certificates) انسٹال کریں
RUN apt-get update && apt-get install -y curl git unzip xz-utils libglu1-mesa ca-certificates

# Flutter SDK ڈاؤن لوڈ کریں
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

# 🛡️ Git ownership issue fix (Docker میں اکثر یہ وارننگ آتی ہے)
RUN git config --global --add safe.directory /flutter

# root وارننگ سے بچنے اور ویب انیبل کرنے کے لیے
RUN flutter config --no-analytics
RUN flutter config --enable-web

WORKDIR /app
COPY . .

# 📦 پیکیجز ڈاؤنلوڈ کریں
RUN flutter pub get

# 🚀 فکس: اگر ویب فولڈر نہیں ہے تو اسے یہاں بنائیں
RUN flutter create . --platforms web

# 🌟 Build Flutter web app
RUN flutter build web --release

# Stage 2: Serve Stage (Nginx)
FROM nginx:alpine

# کسٹم nginx کنفیگ
COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=build-env /app/build/web /usr/share/nginx/html

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
