import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_common_ui/sanyan_common_ui.dart';

void main() {
  // 默认测试 surface 为 800×600。抽屉宽度默认占屏 78% = 624，
  // 打开后主体左移到 x=624，屏幕右侧 [624,800] 是露出的主体遮罩区。
  Widget wrap(SlideDrawerController c) => MaterialApp(
        home: SlideDrawerScaffold(
          controller: c,
          drawer: Container(key: const Key('drawer'), color: const Color(0xFF112233)),
          body: Container(key: const Key('body'), color: const Color(0xFFFFFFFF)),
        ),
      );

  group('SlideDrawerScaffold', () {
    testWidgets('关闭时主体在最左（dx=0）', (tester) async {
      final c = SlideDrawerController();
      await tester.pumpWidget(wrap(c));
      expect(tester.getTopLeft(find.byKey(const Key('body'))).dx, 0);
    });

    testWidgets('抽屉在底层始终渲染', (tester) async {
      final c = SlideDrawerController();
      await tester.pumpWidget(wrap(c));
      expect(find.byKey(const Key('drawer')), findsOneWidget);
    });

    testWidgets('打开后主体整体右移露出抽屉（dx>0）', (tester) async {
      final c = SlideDrawerController();
      await tester.pumpWidget(wrap(c));
      c.open();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const Key('body'))).dx, greaterThan(0));
    });

    testWidgets('纯平移：主体宽度不变（不缩放）', (tester) async {
      final c = SlideDrawerController();
      await tester.pumpWidget(wrap(c));
      final closedWidth = tester.getSize(find.byKey(const Key('body'))).width;
      c.open();
      await tester.pumpAndSettle();
      final openWidth = tester.getSize(find.byKey(const Key('body'))).width;
      expect(openWidth, closedWidth);
    });

    testWidgets('打开后点击露出的主体区域关闭抽屉', (tester) async {
      final c = SlideDrawerController();
      await tester.pumpWidget(wrap(c));
      c.open();
      await tester.pumpAndSettle();
      // 点屏幕右侧 [624,800] 区间内的露出主体（遮罩）
      await tester.tapAt(const Offset(790, 300));
      await tester.pumpAndSettle();
      expect(c.isOpen, isFalse);
      expect(tester.getTopLeft(find.byKey(const Key('body'))).dx, 0);
    });
  });
}
