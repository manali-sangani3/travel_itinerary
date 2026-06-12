import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _api;
  final FlutterSecureStorage _storage;

  AuthBloc(this._api, this._storage) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<ProfileLoadRequested>(_onLoadProfile);
    on<ProfileUpdateRequested>(_onUpdateProfile);
  }

  Future<void> _onLogin(LoginRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final data = await _api.post('/auth/login', data: {'email': e.email, 'password': e.password});
      await _storage.write(key: AppConstants.accessTokenKey, value: data['accessToken']);
      await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
      emit(AuthAuthenticated(null));
      add(ProfileLoadRequested());
    } on AuthException { emit(const AuthError('Invalid email or password')); }
    on ServerException catch (e) { emit(AuthError(e.message)); }
    catch (_) { emit(const AuthError('Login failed')); }
  }

  Future<void> _onRegister(RegisterRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _api.post('/auth/register', data: {'email': e.email, 'password': e.password});
      emit(AuthRegistered());
    } on ServerException catch (ex) { emit(AuthError(ex.message)); }
    catch (_) { emit(const AuthError('Registration failed')); }
  }

  Future<void> _onLogout(LogoutRequested e, Emitter<AuthState> emit) async {
    await _storage.deleteAll();
    emit(AuthUnauthenticated());
  }

  Future<void> _onLoadProfile(ProfileLoadRequested e, Emitter<AuthState> emit) async {
    try {
      final data = await _api.get('/auth/profile');
      final user = User(
        id: data['id'], email: data['email'],
        travelPreferences: Map<String, dynamic>.from(data['travel_preferences'] ?? {}),
        passportDetails: data['passport_details'] != null ? Map<String, dynamic>.from(data['passport_details']) : null,
      );
      emit(AuthAuthenticated(user));
    } catch (_) {}
  }

  Future<void> _onUpdateProfile(ProfileUpdateRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _api.put('/auth/profile', data: e.data);
      emit(ProfileUpdated());
      add(ProfileLoadRequested());
    } on ServerException catch (ex) { emit(AuthError(ex.message)); }
    catch (_) { emit(const AuthError('Update failed')); }
  }
}
