import 'package:sanyan_network/sanyan_network.dart';

class UserApi {
  static final _client = ApiClient();

  static Future<ApiResponse<Map<String, dynamic>>> getProfile() =>
      _client.get('/api/user/profile', fromData: (d) => d as Map<String, dynamic>);

  static Future<ApiResponse> updateProfile({String? nickname, String? avatar}) =>
      _client.put('/api/user/profile', data: {'nickname': nickname, 'avatar': avatar});
}
