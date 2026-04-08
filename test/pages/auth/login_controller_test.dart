import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_app/pages/auth/login_controller.dart';

void main() {
  test('should validate empty phone', () {
    final controller = LoginController();
    expect(controller.validatePhone(''), '请输入手机号');
  });

  test('should validate phone format', () {
    final controller = LoginController();
    expect(controller.validatePhone('123'), '手机号格式不正确');
    expect(controller.validatePhone('13800138000'), null);
  });

  test('should validate empty password', () {
    final controller = LoginController();
    expect(controller.validatePassword(''), '请输入密码');
  });

  test('should accept valid password', () {
    final controller = LoginController();
    expect(controller.validatePassword('123456'), null);
  });
}
