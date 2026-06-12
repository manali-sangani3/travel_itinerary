import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/trips/presentation/bloc/trips_bloc.dart';
import '../../features/itinerary/presentation/bloc/itinerary_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  const storage = FlutterSecureStorage();
  sl.registerSingleton<FlutterSecureStorage>(storage);

  final apiClient = ApiClient(storage);
  sl.registerSingleton<ApiClient>(apiClient);

  sl.registerFactory(() => AuthBloc(sl(), sl()));
  sl.registerFactory(() => TripsBloc(sl()));
  sl.registerFactory(() => ItineraryBloc(sl()));
}
