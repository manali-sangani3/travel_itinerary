import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import 'interceptors/auth_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient(FlutterSecureStorage storage) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(AuthInterceptor(_dio, storage));
  }

  Dio get dio => _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final res = await _dio.get(path, queryParameters: params);
      return res.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    try {
      final res = await _dio.post(path, data: data);
      return res.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final res = await _dio.put(path, data: data);
      return res.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final res = await _dio.delete(path);
      return res.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> upload(String path, FormData formData) async {
    try {
      final res = await _dio.post(path, data: formData, options: Options(contentType: 'multipart/form-data'));
      return res.data;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Never _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      throw const NetworkException();
    }
    switch (e.response?.statusCode) {
      case 401: throw const AuthException();
      case 403: throw const ForbiddenException();
      case 404: throw ServerException('Not found', statusCode: 404);
      default:
        final msg = e.response?.data?['error'] ?? e.message ?? 'Server error';
        throw ServerException(msg.toString(), statusCode: e.response?.statusCode);
    }
  }
}
