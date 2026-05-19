import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/src/api/models/message.dart';
import 'package:sanyan_chat/src/api/models/message_status.dart';
import 'package:sanyan_chat/src/chat/widget/message_bubble.dart';
import 'package:sanyan_network/sanyan_network.dart';

// Bug 回归：failed 状态的红叹号应当不占气泡 layout 宽度，
// 重发成功（status: failed → sent）后气泡不应向左扩展。
//
// 实现策略：让 indicator 不参与 Row 的横向 sizing（用 Stack 浮在气泡左外侧），
// 这样无论有没有 indicator，bubble 容器的 layout 都不变。

const double _kScreenWidth = 400;

Widget _wrap(Widget child, {double width = _kScreenWidth}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: MaterialApp(
      home: Scaffold(body: SizedBox(width: width, child: child)),
    ),
  );
}

// 长消息确保气泡撑到 maxWidth，才能看出 indicator 是否挤占气泡空间。
const _kLongMsg = '一段很长很长很长的消息内容用来撑满气泡的最大宽度看看到底有多宽对不对';

Message _msg({required MessageStatus? status}) => Message(
  id: 1,
  senderType: SenderType.user,
  content: _kLongMsg,
  createdAt: '2026-05-17T10:00:00Z',
  status: status,
);

/// 找包含消息文字的最内层 padding container（气泡本体），返回它的实际宽度。
double _bubbleWidth(WidgetTester tester) {
  final textFinder = find.text(_kLongMsg);
  final RenderBox box = tester.renderObject(
    find.ancestor(
      of: textFinder,
      matching: find.byType(Container),
    ).first,
  );
  return box.size.width;
}

void main() {
  testWidgets('failed 状态的气泡宽度 与 sent 状态一致（叹号不占气泡 layout）', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: _msg(status: MessageStatus.sent))));
    await tester.pumpAndSettle();
    final sentWidth = _bubbleWidth(tester);

    await tester.pumpWidget(_wrap(MessageBubble(message: _msg(status: MessageStatus.failed))));
    await tester.pumpAndSettle();
    final failedWidth = _bubbleWidth(tester);

    expect(
      failedWidth,
      sentWidth,
      reason: 'failed 状态的气泡宽度应 == sent 状态，红叹号不应挤压气泡',
    );
  });
}
