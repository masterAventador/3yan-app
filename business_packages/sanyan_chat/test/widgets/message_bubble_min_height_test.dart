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

  testWidgets('failed 状态下 indicator 感叹号应与 bubble 垂直中线对齐（不论气泡多高）', (tester) async {
    // 用长消息（17 字折 2 行）测试，bubble 高 ~56，avatar 高 40——indicator 应落在
    // bubble 中线（28-ish）而非 avatar 中线（20-ish），证明跟 bubble 走而非跟 avatar 绑死。
    const text = '我不知道啊。。你的小说。。你来我';
    await tester.pumpWidget(_wrap(
      MessageBubble(message: _msg(text, status: MessageStatus.failed)),
    ));
    await tester.pumpAndSettle();

    final iconBox = tester.renderObject<RenderBox>(find.byIcon(Icons.error));
    final bubbleBox = tester.renderObject<RenderBox>(
      find.ancestor(of: find.text(text), matching: find.byType(Container)).first,
    );

    final iconCenterY = iconBox.localToGlobal(Offset(iconBox.size.width / 2, iconBox.size.height / 2)).dy;
    final bubbleTop = bubbleBox.localToGlobal(Offset.zero).dy;
    final bubbleMidY = bubbleTop + bubbleBox.size.height / 2;

    expect(
      (iconCenterY - bubbleMidY).abs(),
      lessThanOrEqualTo(3),
      reason: '感叹号中心应与 bubble 中线对齐，期望 ≈ $bubbleMidY（bubble 高 ${bubbleBox.size.height}），实际 $iconCenterY',
    );
  });

  testWidgets('failed 状态下 avatar 应保持顶对齐（不跟着 indicator 居中往下走）', (tester) async {
    // 多行 bubble 时 avatar 仍顶对齐——验证 Stack 方案没有把 avatar 也带到中线。
    const text = '我不知道啊。。你的小说。。你来我';
    await tester.pumpWidget(_wrap(
      MessageBubble(message: _msg(text, status: MessageStatus.failed)),
    ));
    await tester.pumpAndSettle();

    final avatarBox = tester.renderObject<RenderBox>(
      find.ancestor(of: find.byIcon(Icons.person), matching: find.byType(Container)).first,
    );
    final bubbleBox = tester.renderObject<RenderBox>(
      find.ancestor(of: find.text(text), matching: find.byType(Container)).first,
    );

    final avatarTop = avatarBox.localToGlobal(Offset.zero).dy;
    final bubbleTop = bubbleBox.localToGlobal(Offset.zero).dy;

    expect(
      (avatarTop - bubbleTop).abs(),
      lessThanOrEqualTo(1),
      reason: 'avatar 顶应与 bubble 顶对齐，差值 ${(avatarTop - bubbleTop).abs()}',
    );
  });
}
