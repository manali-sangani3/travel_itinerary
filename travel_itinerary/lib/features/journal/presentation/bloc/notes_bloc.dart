import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// Model
class TripNote {
  final String id, tripId, content;
  final String? dayDate, locationTag, createdAt;
  TripNote({required this.id, required this.tripId, required this.content, this.dayDate, this.locationTag, this.createdAt});
  factory TripNote.fromJson(Map<String, dynamic> j) => TripNote(
    id: j['id'], tripId: j['trip_id'], content: j['content'],
    dayDate: j['day_date'], locationTag: j['location_tag'], createdAt: j['created_at']
  );
}

// Events
abstract class NotesEvent extends Equatable {
  const NotesEvent();
  @override
  List<Object?> get props => [];
}

class NotesLoadRequested extends NotesEvent {
  final String tripId;
  const NotesLoadRequested(this.tripId);
  @override
  List<Object?> get props => [tripId];
}

class NoteAdded extends NotesEvent {
  final String tripId, content;
  final String? dayDate, locationTag;
  const NoteAdded({required this.tripId, required this.content, this.dayDate, this.locationTag});
  @override
  List<Object?> get props => [tripId, content, dayDate, locationTag];
}

class NoteUpdated extends NotesEvent {
  final String tripId, noteId, content;
  const NoteUpdated({required this.tripId, required this.noteId, required this.content});
  @override
  List<Object?> get props => [tripId, noteId, content];
}

class NoteDeleted extends NotesEvent {
  final String tripId, noteId;
  const NoteDeleted({required this.tripId, required this.noteId});
  @override
  List<Object?> get props => [tripId, noteId];
}

// States
abstract class NotesState extends Equatable {
  const NotesState();
  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {}
class NotesLoading extends NotesState {}
class NotesLoaded extends NotesState {
  final List<TripNote> notes;
  const NotesLoaded(this.notes);
  @override
  List<Object?> get props => [notes];
}
class NotesError extends NotesState {
  final String message;
  const NotesError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final ApiClient _api;
  NotesBloc(this._api) : super(NotesInitial()) {
    on<NotesLoadRequested>((event, emit) async {
      emit(NotesLoading());
      try {
        final data = await _api.get('/trips/${event.tripId}/notes') as List;
        emit(NotesLoaded(data.map((j) => TripNote.fromJson(j)).toList()));
      } catch (e) {
        emit(const NotesError('Failed to load notes'));
      }
    });

    on<NoteAdded>((event, emit) async {
      try {
        await _api.post('/trips/${event.tripId}/notes', data: {
          'content': event.content,
          'dayDate': event.dayDate,
          'locationTag': event.locationTag
        });
        add(NotesLoadRequested(event.tripId));
      } catch (_) {}
    });

    on<NoteUpdated>((event, emit) async {
      try {
        await _api.put('/trips/${event.tripId}/notes/${event.noteId}', data: {'content': event.content});
        add(NotesLoadRequested(event.tripId));
      } catch (_) {}
    });

    on<NoteDeleted>((event, emit) async {
      try {
        await _api.delete('/trips/${event.tripId}/notes/${event.noteId}');
        add(NotesLoadRequested(event.tripId));
      } catch (_) {}
    });
  }
}
