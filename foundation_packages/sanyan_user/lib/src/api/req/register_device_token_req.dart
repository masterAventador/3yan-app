import 'package:sanyan_network/sanyan_network.dart';

/// POST /api/devices/register 请求：客户端上报推送 device token。
/// 本期 L3 实推未通，token 真正获取依赖 iOS .p8 证书 / 安卓推送 SDK（spec §8 待办）。
class RegisterDeviceTokenReq extends BaseReq {
  final String platform; // 'ios' / 'android'
  final String vendor; // 'apns' / 'getui' / 'jpush'
  final String token;

  RegisterDeviceTokenReq({
    required this.platform,
    required this.vendor,
    required this.token,
  });

  @override
  String get path => '/api/devices/register';

  @override
  String get method => 'POST';

  @override
  Map<String, dynamic> toJson() => {
        'platform': platform,
        'vendor': vendor,
        'token': token,
      };
}
