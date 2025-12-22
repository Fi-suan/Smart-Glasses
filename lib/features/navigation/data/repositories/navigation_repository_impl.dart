import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/route.dart';
import '../../domain/repositories/navigation_repository.dart';
import '../datasources/navigation_datasource.dart';
import '../../../../core/utils/logger.dart';

class NavigationRepositoryImpl implements NavigationRepository {
  final NavigationDataSource dataSource;

  NavigationRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, LatLng>> getCurrentLocation() async {
    try {
      final location = await dataSource.getCurrentLocation();
      return Right(location);
    } catch (e) {
      AppLogger.error('Get current location repository error', e);
      return Left(NavigationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NavigationRoute>> getRoute(LatLng start, LatLng end) async {
    try {
      final route = await dataSource.getRoute(start, end);
      return Right(route);
    } catch (e) {
      AppLogger.error('Get route repository error', e);
      return Left(NavigationFailure(e.toString()));
    }
  }

  @override
  Stream<LatLng> trackLocation() {
    return dataSource.trackLocation();
  }

  @override
  Future<Either<Failure, void>> startNavigation(NavigationRoute route) async {
    try {
      await dataSource.startNavigation(route as RouteModel);
      return const Right(null);
    } catch (e) {
      AppLogger.error('Start navigation repository error', e);
      return Left(NavigationFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopNavigation() async {
    try {
      await dataSource.stopNavigation();
      return const Right(null);
    } catch (e) {
      AppLogger.error('Stop navigation repository error', e);
      return Left(NavigationFailure(e.toString()));
    }
  }
}

