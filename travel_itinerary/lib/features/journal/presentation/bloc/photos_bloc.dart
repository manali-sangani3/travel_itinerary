import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

// Model
class TripPhoto {
  final String id, tripId, filePath;
  final String? locationTag, dateTaken, uploadedAt;
  TripPhoto({required this.id, required this.tripId, required this.filePath, this.locationTag, this.dateTaken, this.uploadedAt});
  factory TripPhoto.fromJson(Map<String, dynamic> j) => TripPhoto(
    id: j['id'], tripId: j['trip_id'], filePath: j['file_path'],
    locationTag: j['location_tag'], dateTaken: j['date_taken'], uploadedAt: j['uploaded_at']
  );
}

// Events
abstract class PhotosEvent extends Equatable {
  const PhotosEvent();
  @override
  List<Object?> get props => [];
}

class PhotosLoadRequested extends PhotosEvent {
  final String tripId;
  const PhotosLoadRequested(this.tripId);
  @override
  List<Object?> get props => [tripId];
}

class PhotoUploadRequested extends PhotosEvent {
  final String tripId, filePath;
  final String? locationTag, dateTaken;
  const PhotoUploadRequested({required this.tripId, required this.filePath, this.locationTag, this.dateTaken});
  @override
  List<Object?> get props => [tripId, filePath, locationTag, dateTaken];
}

class PhotoDeleted extends PhotosEvent {
  final String tripId, photoId;
  const PhotoDeleted({required this.tripId, required this.photoId});
  @override
  List<Object?> get props => [tripId, photoId];
}

// States
abstract class PhotosState extends Equatable {
  const PhotosState();
  @override
  List<Object?> get props => [];
}

class PhotosInitial extends PhotosState {}
class PhotosLoading extends PhotosState {}
class PhotosLoaded extends PhotosState {
  final List<TripPhoto> photos;
  const PhotosLoaded(this.photos);
  @override
  List<Object?> get props => [photos];
}
class PhotosError extends PhotosState {
  final String message;
  const PhotosError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class PhotosBloc extends Bloc<PhotosEvent, PhotosState> {
  final ApiClient _api;
  PhotosBloc(this._api) : super(PhotosInitial()) {
    on<PhotosLoadRequested>((event, emit) async {
      emit(PhotosLoading());
      try {
        final data = await _api.get('/trips/${event.tripId}/photos') as List;
        emit(PhotosLoaded(data.map((j) => TripPhoto.fromJson(j)).toList()));
      } catch (e) {
        emit(const PhotosError('Failed to load photos'));
      }
    });

    on<PhotoUploadRequested>((event, emit) async {
      try {
        final formData = FormData.fromMap({
          'photo': await MultipartFile.fromFile(event.filePath, filename: event.filePath.split('/').last),
          if (event.locationTag != null) 'locationTag': event.locationTag,
          if (event.dateTaken != null) 'dateTaken': event.dateTaken,
        });
        await _api.upload('/trips/${event.tripId}/photos', formData);
        add(PhotosLoadRequested(event.tripId));
      } catch (_) {}
    });

    on<PhotoDeleted>((event, emit) async {
      try {
        await _api.delete('/trips/${event.tripId}/photos/${event.photoId}');
        add(PhotosLoadRequested(event.tripId));
      } catch (_) {}
    });
  }
}
