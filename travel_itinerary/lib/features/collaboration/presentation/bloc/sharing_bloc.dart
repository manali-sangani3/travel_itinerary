import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// Model
class TripShare {
  final String id, tripId, shareToken, role, expiresAt;
  TripShare({required this.id, required this.tripId, required this.shareToken, required this.role, required this.expiresAt});
  factory TripShare.fromJson(Map<String, dynamic> j) => TripShare(
    id: j['id'], tripId: j['trip_id'], shareToken: j['share_token'],
    role: j['role'], expiresAt: j['expires_at']
  );
}

// Events
abstract class SharingEvent extends Equatable {
  const SharingEvent();
  @override
  List<Object?> get props => [];
}

class SharingLoadRequested extends SharingEvent {
  final String tripId;
  const SharingLoadRequested(this.tripId);
  @override
  List<Object?> get props => [tripId];
}

class ShareLinkGenerated extends SharingEvent {
  final String tripId, role;
  final int expiresInDays;
  const ShareLinkGenerated({required this.tripId, required this.role, required this.expiresInDays});
  @override
  List<Object?> get props => [tripId, role, expiresInDays];
}

class ShareLinkRevoked extends SharingEvent {
  final String tripId, shareId;
  const ShareLinkRevoked({required this.tripId, required this.shareId});
  @override
  List<Object?> get props => [tripId, shareId];
}

// States
abstract class SharingState extends Equatable {
  const SharingState();
  @override
  List<Object?> get props => [];
}

class SharingInitial extends SharingState {}
class SharingLoading extends SharingState {}
class SharingLoaded extends SharingState {
  final List<TripShare> shares;
  final String? generatedUrl;
  const SharingLoaded({required this.shares, this.generatedUrl});
  @override
  List<Object?> get props => [shares, generatedUrl];
}
class SharingError extends SharingState {
  final String message;
  const SharingError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class SharingBloc extends Bloc<SharingEvent, SharingState> {
  final ApiClient _api;
  SharingBloc(this._api) : super(SharingInitial()) {
    on<SharingLoadRequested>((event, emit) async {
      emit(SharingLoading());
      try {
        final data = await _api.get('/trips/${event.tripId}/share') as List;
        emit(SharingLoaded(shares: data.map((j) => TripShare.fromJson(j)).toList()));
      } catch (e) {
        emit(const SharingError('Failed to load sharing settings'));
      }
    });

    on<ShareLinkGenerated>((event, emit) async {
      try {
        final res = await _api.post('/trips/${event.tripId}/share', data: {
          'role': event.role,
          'expiresInDays': event.expiresInDays
        });
        final data = await _api.get('/trips/${event.tripId}/share') as List;
        emit(SharingLoaded(
          shares: data.map((j) => TripShare.fromJson(j)).toList(),
          generatedUrl: res['shareUrl'],
        ));
      } catch (_) {}
    });

    on<ShareLinkRevoked>((event, emit) async {
      try {
        await _api.delete('/trips/${event.tripId}/share/${event.shareId}');
        add(SharingLoadRequested(event.tripId));
      } catch (_) {}
    });
  }
}
