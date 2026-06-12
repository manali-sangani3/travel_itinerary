class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException(this.message, {this.statusCode});
}

class NetworkException implements Exception { const NetworkException(); }
class CacheException implements Exception { const CacheException(); }
class AuthException implements Exception { const AuthException([this.message = 'Unauthorized']); final String message; }
class ForbiddenException implements Exception { const ForbiddenException(); }
