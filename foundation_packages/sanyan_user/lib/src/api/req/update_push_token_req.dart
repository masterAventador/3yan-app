import 'package:sanyan_network/sanyan_network.dart';

class UpdatePushTokenReq extends BaseReq {
  final String pushToken;
  final String deviceType;

  UpdatePushTokenReq({required this.pushToken, required this.deviceType});

  @override
  String get path => '/api/device/push-token';
  @override
  String get method => 'POST';
  @override
  Map<String, dynamic> toJson() => {
        'pushToken': pushToken,
        'deviceType': deviceType,
      };
}
