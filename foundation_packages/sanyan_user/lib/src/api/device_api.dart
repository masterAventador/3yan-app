import 'package:sanyan_network/sanyan_network.dart';

class DeviceApi {
  static final _client = ApiClient();

  static Future<ApiResponse> updatePushToken(String pushToken, String deviceType) =>
      _client.post('/api/device/push-token',
          data: {'pushToken': pushToken, 'deviceType': deviceType});
}
