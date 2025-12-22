import 'package:equatable/equatable.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class StartNavigation extends NavigationEvent {
  final String destination;

  const StartNavigation(this.destination);

  @override
  List<Object> get props => [destination];
}

class StopNavigation extends NavigationEvent {}

class UpdateLocation extends NavigationEvent {}

