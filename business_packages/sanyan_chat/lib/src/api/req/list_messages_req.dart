import 'package:sanyan_network/sanyan_network.dart';

class ListMessagesReq extends BaseReq {
  final int conversationId;
  final int? beforeId;
  final int limit;

  ListMessagesReq({
    required this.conversationId,
    this.beforeId,
    this.limit = 20,
  });

  @override
  String get path => '/api/conversations/$conversationId/messages';
  @override
  String get method => 'GET';
  @override
  Map<String, dynamic> toJson() => {'beforeId': beforeId, 'limit': limit};
}
