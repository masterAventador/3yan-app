import 'package:sanyan_network/sanyan_network.dart';
import '../models/character.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'req/list_characters_req.dart';
import 'req/get_character_req.dart';
import 'req/list_conversations_req.dart';
import 'req/list_messages_req.dart';
import 'req/mark_read_req.dart';

class CharacterApi {
  static final _client = ApiClient();

  static Future<ApiResponse<List<Character>>> list() =>
      _client.send(
        ListCharactersReq(),
        fromData: (d) => (d as List).map((e) => Character.fromJson(e)).toList(),
      );

  static Future<ApiResponse<Character>> detail(int id) =>
      _client.send(GetCharacterReq(id: id), fromData: (d) => Character.fromJson(d));
}

class ConversationApi {
  static final _client = ApiClient();

  static Future<ApiResponse<List<Conversation>>> list() =>
      _client.send(
        ListConversationsReq(),
        fromData: (d) => (d as List).map((e) => Conversation.fromJson(e)).toList(),
      );

  static Future<ApiResponse<List<Message>>> messages(
    int convId, {
    int? beforeId,
    int limit = 20,
  }) =>
      _client.send(
        ListMessagesReq(conversationId: convId, beforeId: beforeId, limit: limit),
        fromData: (d) => (d as List).map((e) => Message.fromJson(e)).toList(),
      );

  static Future<ApiResponse> markRead(int convId) =>
      _client.send(MarkReadReq(conversationId: convId));
}
