part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email, password;
  const LoginRequested(this.email, this.password);
  @override List<Object> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String email, password;
  const RegisterRequested(this.email, this.password);
  @override List<Object> get props => [email, password];
}

class LogoutRequested extends AuthEvent {}
class ProfileLoadRequested extends AuthEvent {}

class ProfileUpdateRequested extends AuthEvent {
  final Map<String, dynamic> data;
  const ProfileUpdateRequested(this.data);
  @override List<Object> get props => [data];
}
