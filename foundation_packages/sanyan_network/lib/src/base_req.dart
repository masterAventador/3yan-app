abstract class BaseReq {
  String get path;
  String get method;
  Map<String, dynamic> toJson();

  /// GET 请求的查询参数，默认等于 toJson()
  Map<String, dynamic> get queryParams => toJson();
}
