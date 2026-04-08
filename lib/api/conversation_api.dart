import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class ConversationApi {
  static final _client = ApiClient();

  static Future<ApiResponse<List<Conversation>>> list() =>
      _client.get(
        '/api/conversations',
        fromData: (d) => (d as List).map((e) => Conversation.fromJson(e)).toList(),
      );

  static Future<ApiResponse<List<Message>>> messages(
    int convId, {
    int? beforeId,
    int limit = 20,
  }) =>
      _client.get(
        '/api/conversations/$convId/messages',
        params: {'beforeId': beforeId, 'limit': limit},
        fromData: (d) => (d as List).map((e) => Message.fromJson(e)).toList(),
      );

  static Future<ApiResponse> markRead(int convId) =>
      _client.post('/api/conversations/$convId/read');
}
