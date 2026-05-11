import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_response.dart';
import 'app_constants.dart';
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
      debugPrint('[HTTP]${buf.toString()}');
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
      debugPrint('[HTTP]${buf.toString()}');
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

  /// 统一请求入口：把 dio 的 DioException / 其他异常兜住，转成
  /// ApiResponse(success: false, errMsg: 友好文案) 返回——对外契约"永不抛异常"。
  /// 业务层只需检查 resp.success / resp.errMsg，不需要 try-catch。
  Future<ApiResponse<T>> _request<T>({
    required String method,
    required String path,
    Map<String, dynamic>? params,
    Object? data,
    T Function(dynamic)? fromData,
  }) async {
    try {
      final resp = await _dio.request<dynamic>(
        path,
        queryParameters: params,
        data: data,
        options: Options(method: method),
      );
      return ApiResponse.fromJson(resp.data, fromData);
    } on DioException catch (e) {
      return ApiResponse<T>(success: false, errMsg: _friendlyError(e));
    } catch (e) {
      return ApiResponse<T>(success: false, errMsg: '请求异常: $e');
    }
  }

  String _friendlyError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '网络超时，请稍后再试';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return '网络连接失败';
      case DioExceptionType.badResponse:
        return '服务端错误 ${e.response?.statusCode ?? ""}';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.badCertificate:
        return '证书错误';
    }
  }

  Future<ApiResponse<T>> get<T>(String path, {
    Map<String, dynamic>? params,
    T Function(dynamic)? fromData,
  }) =>
      _request<T>(method: 'GET', path: path, params: params, fromData: fromData);

  Future<ApiResponse<T>> post<T>(String path, {
    Map<String, dynamic>? data,
    T Function(dynamic)? fromData,
  }) =>
      _request<T>(method: 'POST', path: path, data: data, fromData: fromData);

  Future<ApiResponse<T>> put<T>(String path, {
    Map<String, dynamic>? data,
    T Function(dynamic)? fromData,
  }) =>
      _request<T>(method: 'PUT', path: path, data: data, fromData: fromData);

  /// POST multipart form data (for file uploads)。和 post/get/put 一样统一兜底。
  Future<ApiResponse<T>> postFormData<T>(String path, {
    required FormData formData,
    T Function(dynamic)? fromData,
  }) =>
      _request<T>(method: 'POST', path: path, data: formData, fromData: fromData);

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
