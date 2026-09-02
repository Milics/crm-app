FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe scripts/sync_server.dart -o bin/sync_server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/sync_server /app/bin/sync_server
COPY --from=build /app/data /app/data

WORKDIR /app
EXPOSE 8888
ENV PORT=8888

CMD ["/app/bin/sync_server"]
