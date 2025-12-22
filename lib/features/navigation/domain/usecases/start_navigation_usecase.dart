import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/error/failures.dart';
import '../entities/route.dart';
import '../repositories/navigation_repository.dart';

class StartNavigationUseCase {
  final NavigationRepository repository;

  StartNavigationUseCase(this.repository);

  Future<Either<Failure, NavigationRoute>> call(String destination) async {
    // Get current location
    final currentLocationResult = await repository.getCurrentLocation();
    
    return await currentLocationResult.fold(
      (failure) => Left(failure),
      (currentLocation) async {
        // For demo purposes, use a mock destination
        // In production, you'd geocode the destination string to LatLng
        final destinationLatLng = LatLng(
          currentLocation.latitude + 0.01,
          currentLocation.longitude + 0.01,
        );
        
        // Get route
        final routeResult = await repository.getRoute(
          currentLocation,
          destinationLatLng,
        );
        
        return routeResult.fold(
          (failure) => Left(failure),
          (route) async {
            // Start navigation
            await repository.startNavigation(route);
            return Right(route);
          },
        );
      },
    );
  }
}

