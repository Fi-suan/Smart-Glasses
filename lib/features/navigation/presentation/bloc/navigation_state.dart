import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/route.dart';

abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object?> get props => [];
}

class NavigationInitial extends NavigationState {}

class NavigationLoading extends NavigationState {}

class NavigationActive extends NavigationState {
  final NavigationRoute route;
  final LatLng? currentLocation;
  final int currentStepIndex;

  const NavigationActive({
    required this.route,
    this.currentLocation,
    this.currentStepIndex = 0,
  });

  @override
  List<Object?> get props => [route, currentLocation, currentStepIndex];
}

class NavigationCompleted extends NavigationState {}

class NavigationError extends NavigationState {
  final String message;

  const NavigationError(this.message);

  @override
  List<Object> get props => [message];
}

