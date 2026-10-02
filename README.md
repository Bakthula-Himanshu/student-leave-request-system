# Student Leave Request System

A Flutter Web + Dart Shelf application for submitting, reviewing, approving, and rejecting student leave requests.

## Architecture

```text
student-leave-request-system/
├── frontend/
│   └── student_app/
│       └── lib/
│           ├── main.dart
│           ├── faculty_main.dart
│           ├── models/
│           ├── services/
│           ├── screens/
│           │   ├── student/
│           │   └── faculty/
│           ├── widgets/
│           └── utils/
├── backend/
│   ├── bin/
│   │   └── server.dart
│   └── lib/
├── docs/
├── .gitignore
├── .env.example
├── LICENSE
└── README.md
```

## Applications

### Student Web
Entry point: `frontend/student_app/lib/main.dart`

### Faculty Web
Entry point: `frontend/student_app/lib/faculty_main.dart`

### Backend
Entry point: `backend/bin/server.dart`

## Local Development

From `frontend/student_app`:

```cmd
flutter pub get
flutter run -d web-server
```

For the faculty web application:

```cmd
flutter run -d web-server -t lib\faculty_main.dart
```

From `backend`:

```cmd
dart pub get
dart run bin\server.dart
```

The current backend uses port `8080` and SQLite.

## API

- `POST /api/leaves`
- `GET /api/leaves`
- `PUT /api/leaves/<id>/status`
- `GET /api/leaves/stats`

See `docs/API.md`.

## Security

The current faculty authentication is a demonstration implementation. It should be replaced with backend-enforced authentication before production deployment.

Do not commit databases, passwords, API keys, or `.env` files containing secrets.

## License

MIT
