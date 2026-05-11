import 'package:sanyan_network/sanyan_network.dart';
import 'models/message.dart';
import 'req/list_messages_req.dart';

abstract class ChatApi {
  static final _client = ApiClient();

  /// 拉取历史消息（按时间正序）
  static Future<ApiResponse<List<Message>>> listMessages({int? beforeId, int limit = 20}) =>
      _client.send(
        ListMessagesReq(beforeId: beforeId, limit: limit),
        fromData: (d) => (d as List).map((e) => Message.fromJson(e)).toList(),
      );
}
