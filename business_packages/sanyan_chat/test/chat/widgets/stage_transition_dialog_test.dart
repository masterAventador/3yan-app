import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/src/chat/widgets/stage_transition_dialog.dart';

void main() {
  group('showStageTransitionDialog', () {
    testWidgets('shows story_message text', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
        return TextButton(
          onPressed: () => showStageTransitionDialog(
            ctx,
            fromStage: 1,
            toStage: 2,
            storyMessage: '她半夜悄悄想你……',
          ),
          child: const Text('open'),
        );
      })));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('她半夜悄悄想你……'), findsOneWidget);
    });

    testWidgets('dismisses on tap', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
        return TextButton(
          onPressed: () => showStageTransitionDialog(
            ctx,
            fromStage: 1,
            toStage: 2,
            storyMessage: '测试文案',
          ),
          child: const Text('open'),
        );
      })));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('测试文案'), findsOneWidget);

      // tap outside the card (top of screen)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('测试文案'), findsNothing);
    });

    testWidgets('shows favorite icon', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (ctx) {
        return TextButton(
          onPressed: () => showStageTransitionDialog(
            ctx,
            fromStage: 0,
            toStage: 1,
            storyMessage: 'x',
          ),
          child: const Text('open'),
        );
      })));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });
}
