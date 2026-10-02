# Deployment

For online deployment:

1. Deploy `backend` to a server that can run Dart.
2. Use a hosted database for production rather than a local SQLite file if multiple users need concurrent access.
3. Build the Flutter Web frontend from `frontend/student_app`.
4. Configure the deployed frontend to use the public backend URL instead of `localhost`.
5. Deploy the student and faculty web entrypoints.
6. Test the complete submit → review → approve/reject → status flow.

The current faculty login is for demonstration and should not be treated as production authentication.
