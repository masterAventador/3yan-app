import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/src/api/models/relationship.dart';
import 'package:sanyan_chat/src/chat/widgets/intimacy_progress_bar.dart';

void main() {
  group('IntimacyProgressBar', () {
    testWidgets('renders stage name and score / threshold', (tester) async {
      final rel = Relationship(
        userId: 1, characterId: 1, intimacyScore: 250, currentStage: 1,
        currentStageName: '朋友', nextStageThreshold: 300, percentToNextStage: 0.75,
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: IntimacyProgressBar(relationship: rel),
      )));

      expect(find.text('朋友'), findsOneWidget);
      expect(find.text('250 / 300'), findsOneWidget);
    });

    testWidgets('renders ∞ for top stage threshold', (tester) async {
      final rel = Relationship(
        userId: 1, characterId: 1, intimacyScore: 9999, currentStage: 4,
        currentStageName: '老夫老妻', nextStageThreshold: 2147483647, percentToNextStage: 1.0,
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: IntimacyProgressBar(relationship: rel),
      )));

      expect(find.text('老夫老妻'), findsOneWidget);
      expect(find.text('9999 / ∞'), findsOneWidget);
    });

    testWidgets('progress fill matches percent', (tester) async {
      final rel = Relationship(
        userId: 1, characterId: 1, intimacyScore: 250, currentStage: 1,
        currentStageName: '朋友', nextStageThreshold: 300, percentToNextStage: 0.75,
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: IntimacyProgressBar(relationship: rel),
      )));

      final fraction = tester.widget<FractionallySizedBox>(
          find.byType(FractionallySizedBox));
      expect(fraction.widthFactor, closeTo(0.75, 0.001));
    });

    testWidgets('onTap callback fires', (tester) async {
      var tapped = false;
      final rel = Relationship(
        userId: 1, characterId: 1, intimacyScore: 100, currentStage: 1,
        currentStageName: '朋友', nextStageThreshold: 300, percentToNextStage: 0.0,
      );
      // 用 Material 直接包裹避免 Scaffold body padding 影响 hit testing
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: IntimacyProgressBar(
            relationship: rel,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tapAt(tester.getTopLeft(find.byType(GestureDetector)) + const Offset(20, 10));
      expect(tapped, isTrue);
    });

    testWidgets('clamps percent above 1.0', (tester) async {
      final rel = Relationship(
        userId: 1, characterId: 1, intimacyScore: 9999, currentStage: 4,
        currentStageName: '老夫老妻', nextStageThreshold: 2147483647, percentToNextStage: 5.0,
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: IntimacyProgressBar(relationship: rel),
      )));

      final fraction = tester.widget<FractionallySizedBox>(
          find.byType(FractionallySizedBox));
      expect(fraction.widthFactor, 1.0);
    });
  });
}
