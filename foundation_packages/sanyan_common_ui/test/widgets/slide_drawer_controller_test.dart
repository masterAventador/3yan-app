import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';

void main() {
  group('SlideDrawerController', () {
    test('初始状态为关闭', () {
      final c = SlideDrawerController();
      expect(c.isOpen, isFalse);
    });

    test('open() 打开抽屉', () {
      final c = SlideDrawerController();
      c.open();
      expect(c.isOpen, isTrue);
    });

    test('close() 关闭抽屉', () {
      final c = SlideDrawerController()..open();
      c.close();
      expect(c.isOpen, isFalse);
    });

    test('toggle() 在开/关之间切换', () {
      final c = SlideDrawerController();
      c.toggle();
      expect(c.isOpen, isTrue);
      c.toggle();
      expect(c.isOpen, isFalse);
    });

    test('状态变化时通知监听者', () {
      final c = SlideDrawerController();
      var notified = 0;
      c.addListener(() => notified++);
      c.open();
      expect(notified, 1);
    });

    test('重复 open() 不重复通知（状态没变不刷新动画）', () {
      final c = SlideDrawerController()..open();
      var notified = 0;
      c.addListener(() => notified++);
      c.open();
      expect(notified, 0);
    });

    test('重复 close() 不重复通知', () {
      final c = SlideDrawerController();
      var notified = 0;
      c.addListener(() => notified++);
      c.close();
      expect(notified, 0);
    });
  });
}
