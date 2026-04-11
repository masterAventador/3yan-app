import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      onResponse: (response, handler) {
        _logResponse(response);
        handler.next(response);
      },
      onError: (err, handler) {
        _logError(err);
        handler.next(err);
      },
    ));
  }

  void _logResponse(Response response) {
    final opts = response.requestOptions;
    final paramsStr = _prettyJson(
      opts.method == 'GET' ? opts.queryParameters : opts.data,
    );
    final respStr = _prettyJson(response.data);

    final buf = StringBuffer();
    buf.writeln('\n╔══════════════════════════════════════════════════════════════');
    buf.writeln('║ ${opts.method} ${opts.uri}');
    buf.writeln('║ Token: ${opts.headers['Authorization'] ?? 'null'}');
    buf.writeln('╠══════════════════════════════════════════════════════════════');
    buf.writeln('║ 请求参数:');
    buf.writeln(paramsStr);
    buf.writeln('╠══════════════════════════════════════════════════════════════');
    buf.writeln('║ 响应数据:');
    buf.writeln(respStr);
    buf.writeln('╚══════════════════════════════════════════════════════════════');

    if (kDebugMode) {
      developer.log(buf.toString(), name: 'HTTP');
    }
  }

  void _logError(DioException err) {
    final opts = err.requestOptions;
    final buf = StringBuffer();
    buf.writeln('\n╔══════════════════════════════════════════════════════════════');
    buf.writeln('║ ❌ ${opts.method} ${opts.uri}');
    buf.writeln('║ Token: ${opts.headers['Authorization'] ?? 'null'}');
    buf.writeln('╠══════════════════════════════════════════════════════════════');
    buf.writeln('║ 错误类型: ${err.type}');
    buf.writeln('║ 错误信息: ${err.message}');
    if (err.response != null) {
      buf.writeln('║ 状态码: ${err.response!.statusCode}');
      buf.writeln('║ 响应数据: ${_prettyJson(err.response!.data)}');
    }
    buf.writeln('╚══════════════════════════════════════════════════════════════');

    if (kDebugMode) {
      developer.log(buf.toString(), name: 'HTTP', error: err);
    }
  }

  String _prettyJson(dynamic data) {
    final raw = () {
      if (data == null) return 'null';
      try {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(data);
      } catch (_) {
        return data.toString();
      }
    }();
    return raw.split('\n').map((line) => '║ $line').join('\n');
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

  /// POST multipart form data (for file uploads)
  Future<dynamic> postFormData(String path, {required FormData formData}) async {
    final resp = await _dio.post(path, data: formData);
    return resp.data;
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
