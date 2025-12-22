import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/error/failures.dart';
import '../entities/route.dart';

abstract class NavigationRepository {
  Future<Either<Failure, LatLng>> getCurrentLocation();
  Future<Either<Failure, NavigationRoute>> getRoute(LatLng start, LatLng end);
  Stream<LatLng> trackLocation();
  Future<Either<Failure, void>> startNavigation(NavigationRoute route);
  Future<Either<Failure, void>> stopNavigation();
}

