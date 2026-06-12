import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure { const ServerFailure(super.message); }
class NetworkFailure extends Failure { const NetworkFailure([super.message = 'No internet connection']); }
class CacheFailure extends Failure { const CacheFailure([super.message = 'Cache error']); }
class AuthFailure extends Failure { const AuthFailure([super.message = 'Authentication failed']); }
class ValidationFailure extends Failure { const ValidationFailure(super.message); }
class NotFoundFailure extends Failure { const NotFoundFailure([super.message = 'Not found']); }
class ForbiddenFailure extends Failure { const ForbiddenFailure([super.message = 'Access denied']); }
