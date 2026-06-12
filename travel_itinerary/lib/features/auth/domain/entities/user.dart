import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final Map<String, dynamic> travelPreferences;
  final Map<String, dynamic>? passportDetails;

  const User({required this.id, required this.email, this.travelPreferences = const {}, this.passportDetails});

  @override
  List<Object?> get props => [id, email];
}

class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;
  const AuthTokens({required this.accessToken, required this.refreshToken});
  @override
  List<Object> get props => [accessToken, refreshToken];
}
