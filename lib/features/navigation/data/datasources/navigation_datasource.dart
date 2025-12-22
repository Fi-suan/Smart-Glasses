import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/route_model.dart';
import '../../../../core/utils/logger.dart';

abstract class NavigationDataSource {
  Future<LatLng> getCurrentLocation();
  Future<RouteModel> getRoute(LatLng start, LatLng end);
  Stream<LatLng> trackLocation();
  Future<void> startNavigation(RouteModel route);
  Future<void> stopNavigation();
}

class NavigationDataSourceImpl implements NavigationDataSource {
  StreamSubscription<Position>? _locationSubscription;

  @override
  Future<LatLng> getCurrentLocation() async {
    try {
      // Request location permission
      final locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        throw Exception('Location permission required');
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      AppLogger.error('Get current location error', e);
      rethrow;
    }
  }

  @override
  Future<RouteModel> getRoute(LatLng start, LatLng end) async {
    try {
      // In a real app, you would call Google Directions API here
      // For MVP, return a mock route
      
      final mockSteps = [
        RouteStepModel(
          instruction: 'Head north on Main St',
          distanceInMeters: 500,
          durationInSeconds: 60,
          location: start,
        ),
        RouteStepModel(
          instruction: 'Turn right onto Oak Ave',
          distanceInMeters: 300,
          durationInSeconds: 45,
          location: LatLng(
            start.latitude + 0.005,
            start.longitude,
          ),
        ),
        RouteStepModel(
          instruction: 'Destination will be on your left',
          distanceInMeters: 200,
          durationInSeconds: 30,
          location: end,
        ),
      ];

      return RouteModel(
        destination: 'Destination',
        startLocation: start,
        endLocation: end,
        polylinePoints: [start, end], // Simplified
        distanceInMeters: 1000,
        durationInSeconds: 135,
        steps: mockSteps,
      );
    } catch (e) {
      AppLogger.error('Get route error', e);
      rethrow;
    }
  }

  @override
  Stream<LatLng> trackLocation() {
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) {
      return LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Future<void> startNavigation(RouteModel route) async {
    AppLogger.info('Navigation started to: ${route.destination}');
    // In a real app, this would initialize turn-by-turn navigation
  }

  @override
  Future<void> stopNavigation() async {
    await _locationSubscription?.cancel();
    AppLogger.info('Navigation stopped');
  }
}

