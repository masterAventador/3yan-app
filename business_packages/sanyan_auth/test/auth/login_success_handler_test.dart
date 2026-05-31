import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sanyan_user/sanyan_user.dart';
import 'package:sanyan_auth/src/auth/login_success_handler.dart';

class _SpyHandler extends LoginSuccessHandlerImpl {
  int connectCount = 0;
  int navCount = 0;
  int pushCount = 0;
  @override
  void connectWs() => connectCount++;
  @override
  void navigateToChat() => navCount++;
  @override
  void registerPushToken() => pushCount++;
}

/// GetStorage.init() 在非 web 平台依赖 path_provider 拿目录，
/// 测试环境无原生实现，这里用临时目录的 fake 实现兜底。
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String _dir = Directory.systemTemp.createTempSync('sy_auth_test').path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _dir;

  @override
  Future<String?> getTemporaryPath() async => _dir;

  @override
  Future<String?> getApplicationSupportPath() async => _dir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    PathProviderPlatform.instance = _FakePathProvider();
    await LocalStorage.init();
  });

  test('handle writes token+userId and triggers push/ws/nav once', () {
    final h = _SpyHandler();
    h.handle(token: 'jwt-1', userId: 7);
    expect(LocalStorage.token, 'jwt-1');
    expect(LocalStorage.userId, 7);
    expect(h.pushCount, 1);
    expect(h.connectCount, 1);
    expect(h.navCount, 1);
  });

  test('handle with registerPush=false skips push but still ws/nav', () {
    final h = _SpyHandler();
    h.handle(token: 'jwt-2', userId: 9, registerPush: false);
    expect(LocalStorage.token, 'jwt-2');
    expect(LocalStorage.userId, 9);
    expect(h.pushCount, 0);
    expect(h.connectCount, 1);
    expect(h.navCount, 1);
  });
}
