/// An HTTP response that the dORM engine could not accept.
class HttpDatabaseException implements Exception {
  final int statusCode;
  final String method;
  final Uri uri;
  final String body;

  const HttpDatabaseException({
    required this.statusCode,
    required this.method,
    required this.uri,
    required this.body,
  });

  @override
  String toString() {
    return 'HttpDatabaseException($statusCode $method $uri: $body)';
  }
}
