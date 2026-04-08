class ApiResponse<T> {
  final bool success;
  final String? errMsg;
  final T? data;

  ApiResponse({required this.success, this.errMsg, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromData) {
    return ApiResponse(
      success: json['success'] ?? false,
      errMsg: json['errMsg'],
      data: json['data'] != null && fromData != null ? fromData(json['data']) : json['data'],
    );
  }
}
