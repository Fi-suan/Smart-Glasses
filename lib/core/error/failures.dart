import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network connection failed']) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed']) : super(message);
}

class DeviceFailure extends Failure {
  const DeviceFailure([String message = 'Device connection failed']) : super(message);
}

class VoiceFailure extends Failure {
  const VoiceFailure([String message = 'Voice recognition failed']) : super(message);
}

class NavigationFailure extends Failure {
  const NavigationFailure([String message = 'Navigation error']) : super(message);
}

