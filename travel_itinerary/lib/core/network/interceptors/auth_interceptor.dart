import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage storage;

  AuthInterceptor(this.dio, this.storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: AppConstants.accessTokenKey);
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await storage.read(key: AppConstants.refreshTokenKey);
        if (refreshToken == null) return handler.next(err);

        final res = await dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
        final newAccess = res.data['accessToken'];
        final newRefresh = res.data['refreshToken'];

        await storage.write(key: AppConstants.accessTokenKey, value: newAccess);
        await storage.write(key: AppConstants.refreshTokenKey, value: newRefresh);

        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retry = await dio.fetch(err.requestOptions);
        return handler.resolve(retry);
      } catch (_) {
        await storage.deleteAll();
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}
