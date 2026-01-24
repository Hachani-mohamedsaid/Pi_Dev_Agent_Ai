/// Exceptions thrown by the Data layer.
///
/// These should be caught and translated to Failures (in Domain) if/when you
/// introduce explicit error handling (Either/Result, etc.).
class ServerException implements Exception {
  const ServerException([this.message]);
  final String? message;

  @override
  String toString() => 'ServerException(message: $message)';
}

class CacheException implements Exception {
  const CacheException([this.message]);
  final String? message;

  @override
  String toString() => 'CacheException(message: $message)';
}


