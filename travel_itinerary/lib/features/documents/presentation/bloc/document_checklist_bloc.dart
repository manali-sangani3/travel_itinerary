import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// Model
class DocumentChecklistItem {
  final String id, tripId, label;
  final bool checked;
  DocumentChecklistItem({required this.id, required this.tripId, required this.label, required this.checked});
  factory DocumentChecklistItem.fromJson(Map<String, dynamic> j) => DocumentChecklistItem(
    id: j['id'], tripId: j['trip_id'], label: j['label'], checked: j['checked'] == 1
  );
}

// Events
abstract class DocumentChecklistEvent extends Equatable {
  const DocumentChecklistEvent();
  @override
  List<Object?> get props => [];
}

class DocumentChecklistLoadRequested extends DocumentChecklistEvent {
  final String tripId;
  const DocumentChecklistLoadRequested(this.tripId);
  @override
  List<Object?> get props => [tripId];
}

class DocumentChecklistToggled extends DocumentChecklistEvent {
  final String tripId, itemId;
  final bool checked;
  const DocumentChecklistToggled({required this.tripId, required this.itemId, required this.checked});
  @override
  List<Object?> get props => [tripId, itemId, checked];
}

// States
abstract class DocumentChecklistState extends Equatable {
  const DocumentChecklistState();
  @override
  List<Object?> get props => [];
}

class DocumentChecklistInitial extends DocumentChecklistState {}
class DocumentChecklistLoading extends DocumentChecklistState {}
class DocumentChecklistLoaded extends DocumentChecklistState {
  final List<DocumentChecklistItem> items;
  const DocumentChecklistLoaded(this.items);
  @override
  List<Object?> get props => [items];
}
class DocumentChecklistError extends DocumentChecklistState {
  final String message;
  const DocumentChecklistError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class DocumentChecklistBloc extends Bloc<DocumentChecklistEvent, DocumentChecklistState> {
  final ApiClient _api;
  DocumentChecklistBloc(this._api) : super(DocumentChecklistInitial()) {
    on<DocumentChecklistLoadRequested>((event, emit) async {
      emit(DocumentChecklistLoading());
      try {
        final data = await _api.get('/trips/${event.tripId}/checklist/documents') as List;
        emit(DocumentChecklistLoaded(data.map((j) => DocumentChecklistItem.fromJson(j)).toList()));
      } catch (e) {
        emit(const DocumentChecklistError('Failed to load document checklist'));
      }
    });

    on<DocumentChecklistToggled>((event, emit) async {
      try {
        await _api.put('/trips/${event.tripId}/checklist/documents', data: {
          'itemId': event.itemId,
          'checked': event.checked
        });
        add(DocumentChecklistLoadRequested(event.tripId));
      } catch (_) {}
    });
  }
}
