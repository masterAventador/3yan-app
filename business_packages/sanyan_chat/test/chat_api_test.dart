import 'package:flutter_test/flutter_test.dart';
import 'package:sanyan_chat/src/api/chat_api.dart';
import 'package:sanyan_chat/src/api/models/relationship.dart';
import 'package:sanyan_chat/src/api/req/relationship_req.dart';
import 'package:sanyan_network/sanyan_network.dart';

void main() {
  group('ChatApi.fetchMyRelationship', () {
    test('方法签名：返回 Future<ApiResponse<Relationship>>', () {
      // 验证 fetchMyRelationship 是 static 方法且返回类型正确。
      // 通过类型系统在编译期校验：若方法不存在则编译失败（RED）。
      final Future<ApiResponse<Relationship>> result = ChatApi.fetchMyRelationship();
      // 不 await，只验证返回类型；实际网络调用在集成测试中覆盖。
      expect(result, isA<Future<ApiResponse<Relationship>>>());
    });

    test('fromData 解析器：正确将 JSON 转成 Relationship', () {
      // 验证 API 内部用于解析的 FetchMyRelationshipData.fromJson 解析正确。
      // 这是 fetchMyRelationship 中唯一的"业务逻辑"（解析部分）。
      const json = {
        'userId': 10,
        'characterId': 1,
        'intimacyScore': 180,
        'currentStage': 1,
        'currentStageName': '朋友',
        'nextStageThreshold': 300,
        'percentToNextStage': 0.6,
      };

      // 模拟 ApiClient.send 成功时 fromData 被调用的逻辑：
      // fetchMyRelationship 中 fromData = (d) => FetchMyRelationshipData.fromJson(d).relationship
      // 此处直接测试等价的解析路径。
      final rawApiResponse = ApiResponse<Relationship>.fromJson(
        {'success': true, 'data': json},
        (d) => FetchMyRelationshipData.fromJson(d as Map<String, dynamic>).relationship,
      );

      expect(rawApiResponse.success, isTrue);
      expect(rawApiResponse.data, isNotNull);
      expect(rawApiResponse.data!.userId, 10);
      expect(rawApiResponse.data!.intimacyScore, 180);
      expect(rawApiResponse.data!.currentStageName, '朋友');
      expect(rawApiResponse.data!.percentToNextStage, 0.6);
    });

    test('fromData 解析器：失败响应时 data 为 null', () {
      final rawApiResponse = ApiResponse<Relationship>.fromJson(
        {'success': false, 'errMsg': '未授权'},
        (d) => FetchMyRelationshipData.fromJson(d as Map<String, dynamic>).relationship,
      );

      expect(rawApiResponse.success, isFalse);
      expect(rawApiResponse.errMsg, '未授权');
      expect(rawApiResponse.data, isNull);
    });
  });
}
