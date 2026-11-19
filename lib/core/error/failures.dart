import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.statusCode]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No network connectivity available. Operating in offline mode.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out while contacting server.']);
}

class ConflictFailure extends Failure {
  const ConflictFailure(super.message, [super.statusCode = 409]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.statusCode = 422]);
}

class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local cache error occurred.']);
}
