import '../core/network/api_client.dart';
import '../core/network/api_response.dart';

class DeviceApi {
  static final _client = ApiClient();

  static Future<ApiResponse> updatePushToken(String pushToken, String deviceType) =>
      _client.post('/api/device/push-token',
          data: {'pushToken': pushToken, 'deviceType': deviceType});
}
