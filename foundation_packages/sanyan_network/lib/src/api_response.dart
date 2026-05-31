class ApiResponse<T> {
  final bool success;
  final int? code;
  final String? message;
  final String? errMsg;
  final T? data;

  ApiResponse({required this.success, this.code, this.message, this.errMsg, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromData) {
    return ApiResponse(
      success: json['success'] ?? false,
      code: (json['code'] as num?)?.toInt(),
      message: json['message'] as String?,
      errMsg: json['errMsg'] ?? json['message'],
      data: json['data'] != null && fromData != null ? fromData(json['data']) : json['data'],
    );
  }
}
