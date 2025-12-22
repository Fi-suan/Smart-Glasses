import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/start_navigation_usecase.dart';
import 'navigation_event.dart';
import 'navigation_state.dart';
import '../../../../core/utils/logger.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final StartNavigationUseCase startNavigationUseCase;

  NavigationBloc({
    required this.startNavigationUseCase,
  }) : super(NavigationInitial()) {
    on<StartNavigation>(_onStartNavigation);
    on<StopNavigation>(_onStopNavigation);
    on<UpdateLocation>(_onUpdateLocation);
  }

  Future<void> _onStartNavigation(
    StartNavigation event,
    Emitter<NavigationState> emit,
  ) async {
    emit(NavigationLoading());
    
    final result = await startNavigationUseCase(event.destination);
    
    result.fold(
      (failure) {
        AppLogger.error('Navigation start failed: ${failure.message}');
        emit(NavigationError(failure.message));
      },
      (route) {
        AppLogger.info('Navigation started to: ${route.destination}');
        emit(NavigationActive(route: route));
      },
    );
  }

  Future<void> _onStopNavigation(
    StopNavigation event,
    Emitter<NavigationState> emit,
  ) async {
    emit(NavigationCompleted());
  }

  Future<void> _onUpdateLocation(
    UpdateLocation event,
    Emitter<NavigationState> emit,
  ) async {
    // Update current location during navigation
    if (state is NavigationActive) {
      final currentState = state as NavigationActive;
      // In a real app, you would update the current location here
    }
  }
}

