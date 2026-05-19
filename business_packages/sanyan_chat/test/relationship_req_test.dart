import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/src/api/models/relationship.dart';
import 'package:sanyan_chat/src/api/req/relationship_req.dart';

void main() {
  group('Relationship.fromJson', () {
    test('parses all fields', () {
      final r = Relationship.fromJson({
        'userId': 1,
        'characterId': 1,
        'intimacyScore': 250,
        'currentStage': 1,
        'currentStageName': '朋友',
        'nextStageThreshold': 300,
        'percentToNextStage': 0.75,
      });
      expect(r.userId, 1);
      expect(r.characterId, 1);
      expect(r.intimacyScore, 250);
      expect(r.currentStage, 1);
      expect(r.currentStageName, '朋友');
      expect(r.nextStageThreshold, 300);
      expect(r.percentToNextStage, 0.75);
    });

    test('handles int as double for percentToNextStage', () {
      final r = Relationship.fromJson({
        'userId': 1,
        'characterId': 1,
        'intimacyScore': 100,
        'currentStage': 0,
        'currentStageName': '陌生人',
        'nextStageThreshold': 100,
        'percentToNextStage': 1, // int from server
      });
      expect(r.percentToNextStage, 1.0);
      expect(r.percentToNextStage, isA<double>());
    });
  });

  group('Relationship.copyWith', () {
    test('updates only specified fields', () {
      final r1 = Relationship(
        userId: 1,
        characterId: 1,
        intimacyScore: 100,
        currentStage: 1,
        currentStageName: '朋友',
        nextStageThreshold: 300,
        percentToNextStage: 0.0,
      );
      final r2 = r1.copyWith(intimacyScore: 150);
      expect(r2.intimacyScore, 150);
      expect(r2.userId, 1); // unchanged
      expect(r2.characterId, 1); // unchanged
      expect(r2.currentStage, 1); // unchanged
      expect(r2.currentStageName, '朋友'); // unchanged
      expect(r2.nextStageThreshold, 300); // unchanged
      expect(r2.percentToNextStage, 0.0); // unchanged
    });

    test('updates multiple fields at once', () {
      final r1 = Relationship(
        userId: 1,
        characterId: 1,
        intimacyScore: 100,
        currentStage: 1,
        currentStageName: '朋友',
        nextStageThreshold: 300,
        percentToNextStage: 0.3,
      );
      final r2 = r1.copyWith(
        intimacyScore: 200,
        currentStage: 2,
        currentStageName: '好友',
        nextStageThreshold: 500,
        percentToNextStage: 0.5,
      );
      expect(r2.intimacyScore, 200);
      expect(r2.currentStage, 2);
      expect(r2.currentStageName, '好友');
      expect(r2.nextStageThreshold, 500);
      expect(r2.percentToNextStage, 0.5);
    });
  });

  group('FetchMyRelationshipReq', () {
    test('path is /api/relationships/me', () {
      expect(FetchMyRelationshipReq().path, '/api/relationships/me');
    });

    test('method is GET', () {
      expect(FetchMyRelationshipReq().method, 'GET');
    });

    test('toJson returns empty map', () {
      expect(FetchMyRelationshipReq().toJson(), isEmpty);
    });
  });

  group('FetchMyRelationshipData', () {
    test('wraps Relationship correctly', () {
      final data = FetchMyRelationshipData.fromJson({
        'userId': 1,
        'characterId': 1,
        'intimacyScore': 100,
        'currentStage': 1,
        'currentStageName': '朋友',
        'nextStageThreshold': 300,
        'percentToNextStage': 0.0,
      });
      expect(data.relationship.intimacyScore, 100);
      expect(data.relationship.currentStageName, '朋友');
    });
  });
}
