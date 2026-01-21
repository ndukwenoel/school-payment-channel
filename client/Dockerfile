# Stage 1: Build Flutter Web
FROM debian:latest AS build-env

# Install dependencies for Flutter
RUN apt-get update && apt-get install -y curl git unzip

# Define Flutter version
ARG FLUTTER_SDK=/usr/local/flutter
ARG FLUTTER_VERSION=3.16.0

# Clone Flutter
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_SDK
RUN cd $FLUTTER_SDK && git checkout stable

# Add Flutter to path
ENV PATH="$FLUTTER_SDK/bin:$FLUTTER_SDK/bin/cache/dart-sdk/bin:${PATH}"

WORKDIR /app
COPY . .

# Get dependencies and build
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
