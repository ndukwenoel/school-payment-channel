import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio _dio;

  ApiClient()
      : _dio = Dio(BaseOptions(
          // Issue 16: Dynamic base URL for Emulator/Web/Local
          baseUrl: (Platform.isAndroid) ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000',
          connectTimeout: const Duration(milliseconds: 5000),
          receiveTimeout: const Duration(milliseconds: 3000),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      // Issue 19: Global 401 Interceptor
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('access_token');
          await prefs.remove('user_id');
          await prefs.remove('role');
          // In a real app, we'd trigger a stream or event to redirect to Login
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
