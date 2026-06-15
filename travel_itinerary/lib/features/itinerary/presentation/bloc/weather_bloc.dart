import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/api_client.dart';

// Events
abstract class WeatherEvent extends Equatable {
  const WeatherEvent();
  @override
  List<Object?> get props => [];
}

class WeatherLoadRequested extends WeatherEvent {
  final String destination;
  final String date;
  const WeatherLoadRequested(this.destination, this.date);
  @override
  List<Object?> get props => [destination, date];
}

// States
abstract class WeatherState extends Equatable {
  const WeatherState();
  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {}
class WeatherLoading extends WeatherState {}
class WeatherLoaded extends WeatherState {
  final double temp;
  final String condition;
  final int precipitation;
  const WeatherLoaded({required this.temp, required this.condition, required this.precipitation});
  @override
  List<Object?> get props => [temp, condition, precipitation];
}
class WeatherError extends WeatherState {
  final String message;
  const WeatherError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final ApiClient _api;
  WeatherBloc(this._api) : super(WeatherInitial()) {
    on<WeatherLoadRequested>((event, emit) async {
      emit(WeatherLoading());
      try {
        final res = await _api.get('/weather/${event.destination}/${event.date}');
        emit(WeatherLoaded(
          temp: (res['temp'] as num).toDouble(),
          condition: res['condition'] as String,
          precipitation: (res['precipitation'] as num).toInt(),
        ));
      } catch (e) {
        emit(const WeatherError('Weather unavailable'));
      }
    });
  }
}
