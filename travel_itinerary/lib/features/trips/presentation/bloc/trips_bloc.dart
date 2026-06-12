import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';

part 'trips_event.dart';
part 'trips_state.dart';

class TripModel {
  final String id, destination, startDate, endDate, status, purpose;
  final List<String> companions;
  TripModel({required this.id, required this.destination, required this.startDate, required this.endDate, required this.status, required this.purpose, required this.companions});
  factory TripModel.fromJson(Map<String, dynamic> j) => TripModel(
    id: j['id'], destination: j['destination'], startDate: j['start_date'], endDate: j['end_date'],
    status: j['status'] ?? 'planning', purpose: j['purpose'] ?? '',
    companions: List<String>.from(j['companions'] ?? []),
  );
}

class TripsBloc extends Bloc<TripsEvent, TripsState> {
  final ApiClient _api;
  TripsBloc(this._api) : super(TripsInitial()) {
    on<TripsLoadRequested>(_onLoad);
    on<TripCreateRequested>(_onCreate);
    on<TripUpdateRequested>(_onUpdate);
    on<TripDeleteRequested>(_onDelete);
  }

  Future<void> _onLoad(TripsLoadRequested e, Emitter<TripsState> emit) async {
    emit(TripsLoading());
    try {
      final data = await _api.get('/trips') as List;
      emit(TripsLoaded(data.map((j) => TripModel.fromJson(j)).toList()));
    } on NetworkException { emit(const TripsError('No internet connection')); }
    on ServerException catch (e) { emit(TripsError(e.message)); }
    catch (_) { emit(const TripsError('Failed to load trips')); }
  }

  Future<void> _onCreate(TripCreateRequested e, Emitter<TripsState> emit) async {
    try {
      await _api.post('/trips', data: e.data);
      add(TripsLoadRequested());
    } on ServerException catch (ex) { emit(TripsError(ex.message)); }
  }

  Future<void> _onUpdate(TripUpdateRequested e, Emitter<TripsState> emit) async {
    try {
      await _api.put('/trips/${e.tripId}', data: e.data);
      add(TripsLoadRequested());
    } on ServerException catch (ex) { emit(TripsError(ex.message)); }
  }

  Future<void> _onDelete(TripDeleteRequested e, Emitter<TripsState> emit) async {
    try {
      await _api.delete('/trips/${e.tripId}');
      add(TripsLoadRequested());
    } on ServerException catch (ex) { emit(TripsError(ex.message)); }
  }
}
