import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';

part 'itinerary_event.dart';
part 'itinerary_state.dart';

class ItineraryItem {
  final String id, tripId, title;
  final int dayIndex, orderIndex;
  final String? location, startTime, endTime;
  ItineraryItem({required this.id, required this.tripId, required this.title, required this.dayIndex, required this.orderIndex, this.location, this.startTime, this.endTime});
  factory ItineraryItem.fromJson(Map<String, dynamic> j) => ItineraryItem(
    id: j['id'], tripId: j['trip_id'], title: j['title'], dayIndex: j['day_index'], orderIndex: j['order_index'],
    location: j['location'], startTime: j['start_time'], endTime: j['end_time'],
  );
  ItineraryItem copyWith({int? orderIndex}) => ItineraryItem(id: id, tripId: tripId, title: title, dayIndex: dayIndex, orderIndex: orderIndex ?? this.orderIndex, location: location, startTime: startTime, endTime: endTime);
  Map<String, dynamic> toJson() => {'id': id, 'order_index': orderIndex};
}

class ItineraryBloc extends Bloc<ItineraryEvent, ItineraryState> {
  final ApiClient _api;
  ItineraryBloc(this._api) : super(ItineraryInitial()) {
    on<ItineraryLoadRequested>(_onLoad);
    on<ItineraryItemAdded>(_onAdd);
    on<ItineraryItemUpdated>(_onUpdate);
    on<ItineraryItemDeleted>(_onDelete);
    on<ItineraryItemReordered>(_onReorder);
  }

  Future<void> _onLoad(ItineraryLoadRequested e, Emitter<ItineraryState> emit) async {
    emit(ItineraryLoading());
    try {
      final data = await _api.get('/trips/${e.tripId}/itinerary') as List;
      emit(ItineraryLoaded(data.map((j) => ItineraryItem.fromJson(j)).toList()));
    } on ServerException catch (ex) { emit(ItineraryError(ex.message)); }
    catch (_) { emit(const ItineraryError('Failed to load itinerary')); }
  }

  Future<void> _onAdd(ItineraryItemAdded e, Emitter<ItineraryState> emit) async {
    try {
      await _api.post('/trips/${e.tripId}/itinerary', data: e.data);
      add(ItineraryLoadRequested(e.tripId));
    } on ServerException catch (ex) { emit(ItineraryError(ex.message)); }
  }

  Future<void> _onUpdate(ItineraryItemUpdated e, Emitter<ItineraryState> emit) async {
    try {
      await _api.put('/trips/${e.tripId}/itinerary/${e.itemId}', data: e.data);
      add(ItineraryLoadRequested(e.tripId));
    } on ServerException catch (ex) { emit(ItineraryError(ex.message)); }
  }

  Future<void> _onDelete(ItineraryItemDeleted e, Emitter<ItineraryState> emit) async {
    try {
      await _api.delete('/trips/${e.tripId}/itinerary/${e.itemId}');
      add(ItineraryLoadRequested(e.tripId));
    } on ServerException catch (ex) { emit(ItineraryError(ex.message)); }
  }

  Future<void> _onReorder(ItineraryItemReordered e, Emitter<ItineraryState> emit) async {
    if (state is ItineraryLoaded) {
      final items = List<ItineraryItem>.from((state as ItineraryLoaded).items);
      final dayItems = items.where((i) => i.dayIndex == e.dayIndex).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      final moved = dayItems.removeAt(e.oldIndex);
      dayItems.insert(e.newIndex, moved);
      final updated = dayItems.asMap().entries.map((e) => e.value.copyWith(orderIndex: e.key)).toList();
      final all = items.where((i) => i.dayIndex != e.dayIndex).toList()..addAll(updated);
      emit(ItineraryLoaded(all));
      try {
        await _api.put('/trips/${e.tripId}/itinerary/reorder', data: {'items': updated.map((i) => i.toJson()).toList()});
      } catch (_) {}
    }
  }
}
