import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/trips/presentation/bloc/trips_bloc.dart';
import 'features/itinerary/presentation/bloc/itinerary_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const TravelItineraryApp());
}

class TravelItineraryApp extends StatelessWidget {
  const TravelItineraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()),
        BlocProvider(create: (_) => sl<TripsBloc>()),
        BlocProvider(create: (_) => sl<ItineraryBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Travel Itinerary',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
