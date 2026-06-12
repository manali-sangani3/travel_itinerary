part of 'itinerary_bloc.dart';

abstract class ItineraryEvent extends Equatable {
  const ItineraryEvent();
  @override List<Object?> get props => [];
}
class ItineraryLoadRequested extends ItineraryEvent {
  final String tripId;
  const ItineraryLoadRequested(this.tripId);
  @override List<Object> get props => [tripId];
}
class ItineraryItemAdded extends ItineraryEvent {
  final String tripId; final Map<String, dynamic> data;
  const ItineraryItemAdded(this.tripId, this.data);
  @override List<Object> get props => [tripId, data];
}
class ItineraryItemUpdated extends ItineraryEvent {
  final String tripId, itemId; final Map<String, dynamic> data;
  const ItineraryItemUpdated(this.tripId, this.itemId, this.data);
  @override List<Object> get props => [tripId, itemId, data];
}
class ItineraryItemDeleted extends ItineraryEvent {
  final String tripId, itemId;
  const ItineraryItemDeleted(this.tripId, this.itemId);
  @override List<Object> get props => [tripId, itemId];
}
class ItineraryItemReordered extends ItineraryEvent {
  final String tripId; final int dayIndex, oldIndex, newIndex;
  const ItineraryItemReordered(this.tripId, this.dayIndex, this.oldIndex, this.newIndex);
  @override List<Object> get props => [tripId, dayIndex, oldIndex, newIndex];
}
