import 'package:sanyan_network/sanyan_network.dart';
import 'models/message.dart';
import 'models/relationship.dart';
import 'req/list_messages_req.dart';
import 'req/relationship_req.dart';

abstract class ChatApi {
  static final _client = ApiClient();

  /// 拉取历史消息（按时间正序）
  static Future<ApiResponse<List<Message>>> listMessages({int? beforeId, int limit = 20}) =>
      _client.send(
        ListMessagesReq(beforeId: beforeId, limit: limit),
        fromData: (d) => (d as List).map((e) => Message.fromJson(e)).toList(),
      );

  /// 拉取当前用户与 AI 角色的关系数据
  static Future<ApiResponse<Relationship>> fetchMyRelationship() =>
      _client.send(
        FetchMyRelationshipReq(),
        fromData: (d) => FetchMyRelationshipData.fromJson(d as Map<String, dynamic>).relationship,
      );
}
