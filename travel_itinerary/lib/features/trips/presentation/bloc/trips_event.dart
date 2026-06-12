part of 'trips_bloc.dart';

abstract class TripsEvent extends Equatable {
  const TripsEvent();
  @override List<Object?> get props => [];
}
class TripsLoadRequested extends TripsEvent {}
class TripCreateRequested extends TripsEvent {
  final Map<String, dynamic> data;
  const TripCreateRequested(this.data);
  @override List<Object> get props => [data];
}
class TripUpdateRequested extends TripsEvent {
  final String tripId;
  final Map<String, dynamic> data;
  const TripUpdateRequested(this.tripId, this.data);
  @override List<Object> get props => [tripId, data];
}
class TripDeleteRequested extends TripsEvent {
  final String tripId;
  const TripDeleteRequested(this.tripId);
  @override List<Object> get props => [tripId];
}
