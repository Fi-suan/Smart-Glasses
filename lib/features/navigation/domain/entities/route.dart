import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationRoute extends Equatable {
  final String destination;
  final LatLng startLocation;
  final LatLng endLocation;
  final List<LatLng> polylinePoints;
  final double distanceInMeters;
  final int durationInSeconds;
  final List<RouteStep> steps;

  const NavigationRoute({
    required this.destination,
    required this.startLocation,
    required this.endLocation,
    required this.polylinePoints,
    required this.distanceInMeters,
    required this.durationInSeconds,
    required this.steps,
  });

  @override
  List<Object> get props => [
        destination,
        startLocation,
        endLocation,
        polylinePoints,
        distanceInMeters,
        durationInSeconds,
        steps,
      ];
}

class RouteStep extends Equatable {
  final String instruction;
  final double distanceInMeters;
  final int durationInSeconds;
  final LatLng location;

  const RouteStep({
    required this.instruction,
    required this.distanceInMeters,
    required this.durationInSeconds,
    required this.location,
  });

  @override
  List<Object> get props => [instruction, distanceInMeters, durationInSeconds, location];
}

