import 'package:dio/dio.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';
import 'api_response.dart';
import 'base_req.dart';

/// Provides the token for API requests.
/// Must be set before making authenticated requests.
typedef TokenProvider = String? Function();

class ApiClient {
  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio _dio;

  /// Set this to provide the auth token for requests.
  static TokenProvider? tokenProvider;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
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

  Future<ApiResponse<T>> send<T>(BaseReq req, {
    T Function(dynamic)? fromData,
  }) async {
    switch (req.method) {
      case 'GET':
        return get(req.path, params: req.queryParams, fromData: fromData);
      case 'POST':
        return post(req.path, data: req.toJson(), fromData: fromData);
      case 'PUT':
        return put(req.path, data: req.toJson(), fromData: fromData);
      default:
        throw UnsupportedError('Unsupported method: ${req.method}');
    }
  }
}
