import 'package:sanyan_network/sanyan_network.dart';
import 'req/update_push_token_req.dart';

class DeviceApi {
  static final _client = ApiClient();

  static Future<ApiResponse> updatePushToken(String pushToken, String deviceType) =>
      _client.send(UpdatePushTokenReq(pushToken: pushToken, deviceType: deviceType));
}
