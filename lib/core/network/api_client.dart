import 'package:dio/dio.dart';
import '../constants.dart';
import '../storage/local_storage.dart';
import 'api_response.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = LocalStorage.token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<ApiResponse<T>> get<T>(String path, {
    Map<String, dynamic>? params,
    T Function(dynamic)? fromData,
  }) async {
    final resp = await _dio.get(path, queryParameters: params);
    return ApiResponse.fromJson(resp.data, fromData);
  }

  Future<ApiResponse<T>> post<T>(String path, {
    Map<String, dynamic>? data,
    T Function(dynamic)? fromData,
  }) async {
    final resp = await _dio.post(path, data: data);
    return ApiResponse.fromJson(resp.data, fromData);
  }

  Future<ApiResponse<T>> put<T>(String path, {
    Map<String, dynamic>? data,
    T Function(dynamic)? fromData,
  }) async {
    final resp = await _dio.put(path, data: data);
    return ApiResponse.fromJson(resp.data, fromData);
  }
}
