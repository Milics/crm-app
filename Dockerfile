FROM dart:stable

WORKDIR /app
COPY scripts/sync_server.dart scripts/sync_server.dart
COPY data data

EXPOSE 8888
ENV PORT=8888

CMD ["dart", "run", "scripts/sync_server.dart"]
