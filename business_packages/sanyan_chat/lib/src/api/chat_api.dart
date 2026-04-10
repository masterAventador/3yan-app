import 'package:dio/dio.dart';
import 'package:sanyan_network/sanyan_network.dart';
import '../models/character.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'req/list_characters_req.dart';
import 'req/get_character_req.dart';
import 'req/list_conversations_req.dart';
import 'req/list_messages_req.dart';
import 'req/mark_read_req.dart';

abstract class ChatApi {
  static final _client = ApiClient();

  // Character
  static Future<ApiResponse<List<Character>>> listCharacters() =>
      _client.send(
        ListCharactersReq(),
        fromData: (d) => (d as List).map((e) => Character.fromJson(e)).toList(),
      );

  static Future<ApiResponse<Character>> getCharacter(int id) =>
      _client.send(GetCharacterReq(id: id), fromData: (d) => Character.fromJson(d));

  // Conversation
  static Future<ApiResponse<List<Conversation>>> listConversations() =>
      _client.send(
        ListConversationsReq(),
        fromData: (d) => (d as List).map((e) => Conversation.fromJson(e)).toList(),
      );

  static Future<ApiResponse<List<Message>>> listMessages(
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

  /// Upload voice file to server, returns COS URL and duration
  static Future<ApiResponse<VoiceUploadResult>> uploadVoice(
    String localFilePath, {
    required int duration,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(localFilePath, filename: 'voice.m4a'),
        'type': ContentType.voice,
        'duration': duration,
      });

      final resp = await _client.postFormData(
        '/api/media/upload',
        formData: formData,
      );
      return ApiResponse.fromJson(
        resp as Map<String, dynamic>,
        (data) => VoiceUploadResult.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse(success: false, errMsg: '上传失败: $e');
    }
  }
}

class VoiceUploadResult {
  final String url;
  final int duration;

  VoiceUploadResult({required this.url, required this.duration});

  factory VoiceUploadResult.fromJson(Map<String, dynamic> json) => VoiceUploadResult(
    url: json['url'] ?? '',
    duration: json['duration'] ?? 0,
  );
}
