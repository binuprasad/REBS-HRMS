class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, [this.statusCode]);

  @override
  String toString() => 'ServerException(statusCode: $statusCode, message: $message)';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No Internet Connection']);

  @override
  String toString() => 'NetworkException($message)';
}

class ConflictException implements Exception {
  final String message;
  const ConflictException(this.message);

  @override
  String toString() => 'ConflictException($message)';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException($message)';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Local cache exception']);

  @override
  String toString() => 'CacheException($message)';
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => 'LocationException($message)';
}
