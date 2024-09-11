# Use latest stable channel SDK.
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code (except anything in .dockerignore) and AOT compile app.
COPY . .
RUN dart compile exe bin/chissue.dart -o bin/chissue

# Build minimal serving image from AOT-compiled `/chissue`
# and the pre-built AOT-runtime in the `/runtime/` directory of the base image.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/chissue /app/bin/
COPY --from=build /app/assets /app/assets

# Set the working directory to /app
WORKDIR /app

# Start chissue.
CMD ["/app/bin/chissue"]