/// API service boundary for the Student Leave Request System.
///
/// The current working HTTP implementation is retained in the student/faculty
/// application files. Future API extraction should move those calls here without
/// changing endpoint behavior.
class ApiService {
  const ApiService(this.baseUrl);

  final String baseUrl;
}
