FROM dart:stable

WORKDIR /app

COPY pubspec.* ./

RUN dart pub get

COPY . .

EXPOSE 10000

CMD ["dart", "run", "bin/server.dart"]
