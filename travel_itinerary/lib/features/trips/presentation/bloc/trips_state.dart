part of 'trips_bloc.dart';

abstract class TripsState extends Equatable {
  const TripsState();
  @override List<Object?> get props => [];
}
class TripsInitial extends TripsState {}
class TripsLoading extends TripsState {}
class TripsLoaded extends TripsState {
  final List<TripModel> trips;
  const TripsLoaded(this.trips);
  @override List<Object> get props => [trips];
}
class TripsError extends TripsState {
  final String message;
  const TripsError(this.message);
  @override List<Object> get props => [message];
}
