import 'package:sanyan_network/sanyan_network.dart';
import 'req/send_sms_req.dart';
import 'req/register_req.dart';
import 'req/login_req.dart';
import 'req/register_device_token_req.dart';

abstract class AuthApi {
  static final _client = ApiClient();

  static Future<ApiResponse> sendSms(String phone) =>
      _client.send(SendSmsReq(phone: phone));

  static Future<ApiResponse<Map<String, dynamic>>> register({
    required String phone,
    required String code,
    required String password,
    String? nickname,
  }) =>
      _client.send(
        RegisterReq(phone: phone, code: code, password: password, nickname: nickname),
        fromData: (d) => d as Map<String, dynamic>,
      );

  static Future<ApiResponse<Map<String, dynamic>>> login({
    required String phone,
    required String password,
  }) =>
      _client.send(
        LoginReq(phone: phone, password: password),
        fromData: (d) => d as Map<String, dynamic>,
      );

  /// 上报 device token（推送注册）。本期 L3 实推未通，仅打通通道。
  static Future<ApiResponse> registerDeviceToken({
    required String platform,
    required String vendor,
    required String token,
  }) =>
      _client.send(
        RegisterDeviceTokenReq(platform: platform, vendor: vendor, token: token),
      );

  /// 登录成功后注册推送 token（占位）。
  /// TODO(plan5-push): 接入 iOS APNs(.p8) / 安卓推送 SDK(个推/极光) 后，
  /// 经原生 channel 拿真实 device token 再调 AuthApi.registerDeviceToken。
  /// 当前 token 未接入，直接跳过实发，仅保留入口结构。
  /// 注意：plan5 接入后本方法将变为 async（需发网络请求拿 token 并上报），
  /// 届时 login_controller 调用处必须相应改为 unawaited(...) / await / .then()
  /// 处理返回的 Future，避免静默 unhandled Future。
  static void registerPushTokenAfterLogin() {
    const String? deviceToken = null; // TODO: 接入推送 SDK 后填真实 token
    // ignore: dead_code
    if (deviceToken == null || deviceToken.isEmpty) return;
    // AuthApi.registerDeviceToken(platform: 'ios', vendor: 'apns', token: deviceToken);
  }
}
