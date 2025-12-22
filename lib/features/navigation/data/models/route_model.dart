import '../../domain/entities/route.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteModel extends NavigationRoute {
  const RouteModel({
    required super.destination,
    required super.startLocation,
    required super.endLocation,
    required super.polylinePoints,
    required super.distanceInMeters,
    required super.durationInSeconds,
    required super.steps,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      destination: json['destination'],
      startLocation: LatLng(
        json['startLocation']['lat'],
        json['startLocation']['lng'],
      ),
      endLocation: LatLng(
        json['endLocation']['lat'],
        json['endLocation']['lng'],
      ),
      polylinePoints: (json['polylinePoints'] as List)
          .map((point) => LatLng(point['lat'], point['lng']))
          .toList(),
      distanceInMeters: json['distanceInMeters'],
      durationInSeconds: json['durationInSeconds'],
      steps: (json['steps'] as List)
          .map((step) => RouteStepModel.fromJson(step))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'startLocation': {
        'lat': startLocation.latitude,
        'lng': startLocation.longitude,
      },
      'endLocation': {
        'lat': endLocation.latitude,
        'lng': endLocation.longitude,
      },
      'polylinePoints': polylinePoints
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList(),
      'distanceInMeters': distanceInMeters,
      'durationInSeconds': durationInSeconds,
      'steps': steps.map((step) => (step as RouteStepModel).toJson()).toList(),
    };
  }
}

class RouteStepModel extends RouteStep {
  const RouteStepModel({
    required super.instruction,
    required super.distanceInMeters,
    required super.durationInSeconds,
    required super.location,
  });

  factory RouteStepModel.fromJson(Map<String, dynamic> json) {
    return RouteStepModel(
      instruction: json['instruction'],
      distanceInMeters: json['distanceInMeters'],
      durationInSeconds: json['durationInSeconds'],
      location: LatLng(json['location']['lat'], json['location']['lng']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instruction': instruction,
      'distanceInMeters': distanceInMeters,
      'durationInSeconds': durationInSeconds,
      'location': {
        'lat': location.latitude,
        'lng': location.longitude,
      },
    };
  }
}

