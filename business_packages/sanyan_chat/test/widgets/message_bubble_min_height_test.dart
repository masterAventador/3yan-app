import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/src/api/models/message.dart';
import 'package:sanyan_chat/src/api/models/message_status.dart';
import 'package:sanyan_chat/src/chat/widget/message_bubble.dart';
import 'package:sanyan_chat/src/chat/widget/message_bubble_shell.dart';
import 'package:sanyan_network/sanyan_network.dart';

// 单字短消息也要保证气泡高度 >= kAvatarSize（与头像齐平，避免缩水难看）。

Widget _wrap(Widget child) => MediaQuery(
  data: const MediaQueryData(size: Size(400, 800)),
  child: MaterialApp(home: Scaffold(body: SizedBox(width: 400, child: child))),
);

Message _msg(String text, {MessageStatus? status}) => Message(
  id: 1,
  senderType: SenderType.user,
  content: text,
  createdAt: '2026-05-17T10:00:00Z',
  status: status,
);

Size _bubbleSize(WidgetTester tester, String text) {
  final RenderBox box = tester.renderObject(
    find.ancestor(
      of: find.text(text),
      matching: find.byType(Container),
    ).first,
  );
  return box.size;
}

double _bubbleHeight(WidgetTester tester, String text) => _bubbleSize(tester, text).height;

void main() {
  testWidgets('单字气泡高度应 >= kAvatarSize（跟头像齐平）', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: _msg('好'))));
    await tester.pumpAndSettle();

    final h = _bubbleHeight(tester, '好');
    expect(
      h,
      greaterThanOrEqualTo(kAvatarSize),
      reason: '单字消息气泡高度应该至少 = kAvatarSize($kAvatarSize)，实际 $h',
    );
  });

  testWidgets('单字气泡宽度应贴合文字，不应被撑成最大宽度', (tester) async {
    await tester.pumpWidget(_wrap(MessageBubble(message: _msg('好'))));
    await tester.pumpAndSettle();

    final w = _bubbleSize(tester, '好').width;
    // 屏宽 400、pagePadding 16、avatar+gap 50 → maxBubbleWidth ≈ 268
    // 单字 16px 字号 + 左右各 10 padding，气泡宽度应远小于 100
    expect(
      w,
      lessThan(100),
      reason: '单字消息气泡不应被撑到最大宽度，期望 < 100，实际 $w',
    );
  });

  testWidgets('两行文字（第二行只有 1 字）气泡高度应能容纳完整文本不裁切', (tester) async {
    // dogfood 实测 bug：当文本在 maxWidth 下恰好换行成"第一行满 + 第二行 1 字"时，
    // 气泡仅显示一行高度，第二行被裁切。fontSize=16 + height=1.35 → 单行 ~21.6px，
    // 加 vertical padding 12 → 两行预期 ≈ 55.2px，不应被卡在 ~28-44px。
    // 复现：用 user 报错截图的原文（17 字符），在 maxBubbleWidth=268 / Text 可用宽度=248
    // 下恰好折成 16 字 + 1 字（"我"换到第二行）。
    const text = '我不知道啊。。你的小说。。你来我';
    await tester.pumpWidget(_wrap(MessageBubble(message: _msg(text))));
    await tester.pumpAndSettle();

    final RenderBox textBox = tester.renderObject(find.text(text));
    final double bubbleH = _bubbleHeight(tester, text);
    // textBox 是 RenderParagraph，size 是经过 constraints.constrain 后的——如果父给的 maxHeight
    // 不够会被 clamp。所以直接比 textBox.size.height 看不出裁切；要比 textPainter 真实高度。
    // 但 textBox.size.height 至少 == "我们以为 parent 给的 max"。我们 assert bubble 高度
    // 至少 ≥ 2 行高度 + padding，让父能装下 2 行。
    final double expectedMinFor2Lines = 2 * 16 * 1.35 + 12;  // ≈ 55.2
    expect(
      bubbleH,
      greaterThanOrEqualTo(expectedMinFor2Lines - 1),  // -1 容差给 sub-pixel
      reason: '17 字文本应折 2 行，气泡高度应 >= $expectedMinFor2Lines，实际 $bubbleH。'
              ' textBox.size=${textBox.size}',
    );
  });

  testWidgets('failed 状态下 indicator 感叹号应与 avatar 中线对齐（短气泡时同时与 bubble 中线对齐）', (tester) async {
    // indicator slot 固定 kAvatarSize=40 高，内部 Center 居中 icon → indicator 中心 Y
    // 应与 avatar 中心 Y 一致。短气泡（单字"好"，气泡高 = kAvatarSize=40）时 bubble
    // 中线 = indicator 中线 = avatar 中线三者重合；长气泡时 indicator/avatar 仍中线
    // 对齐（在 Row 顶部 kAvatarSize 区域内），bubble 整体下沿超出但顶部对齐，跟主流 IM 一致。
    await tester.pumpWidget(_wrap(
      MessageBubble(message: _msg('好', status: MessageStatus.failed)),
    ));
    await tester.pumpAndSettle();

    final iconBox = tester.renderObject<RenderBox>(find.byIcon(Icons.error));
    // avatar 是 user 行的最右一个 40x40 Container（含 Icons.person）
    final avatarBox = tester.renderObject<RenderBox>(
      find.ancestor(of: find.byIcon(Icons.person), matching: find.byType(Container)).first,
    );

    final iconCenterY = iconBox.localToGlobal(Offset(iconBox.size.width / 2, iconBox.size.height / 2)).dy;
    final avatarCenterY = avatarBox.localToGlobal(Offset(avatarBox.size.width / 2, avatarBox.size.height / 2)).dy;

    expect(
      (iconCenterY - avatarCenterY).abs(),
      lessThanOrEqualTo(3),
      reason: '感叹号中心应与 avatar 中线对齐，期望 ≈ $avatarCenterY，实际 $iconCenterY',
    );
  });
}
