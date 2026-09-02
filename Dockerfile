FROM dart:stable AS build

WORKDIR /app
COPY scripts/sync_server.dart scripts/sync_server.dart
RUN dart compile exe scripts/sync_server.dart -o bin/sync_server

FROM dart:stable-slim
WORKDIR /app
COPY --from=build /app/bin/sync_server /app/sync_server
COPY data /app/data

EXPOSE 8888
ENV PORT=8888

CMD ["/app/sync_server"]
