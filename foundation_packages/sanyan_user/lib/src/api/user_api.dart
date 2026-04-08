import 'package:sanyan_network/sanyan_network.dart';
import 'req/get_profile_req.dart';
import 'req/update_profile_req.dart';

abstract class UserApi {
  static final _client = ApiClient();

  static Future<ApiResponse<Map<String, dynamic>>> getProfile() =>
      _client.send(GetProfileReq(), fromData: (d) => d as Map<String, dynamic>);

  static Future<ApiResponse> updateProfile({String? nickname, String? avatar}) =>
      _client.send(UpdateProfileReq(nickname: nickname, avatar: avatar));
}
