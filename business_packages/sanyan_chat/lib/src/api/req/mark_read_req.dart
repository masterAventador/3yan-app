import 'package:sanyan_network/sanyan_network.dart';

class MarkReadReq extends BaseReq {
  final int conversationId;

  MarkReadReq({required this.conversationId});

  @override
  String get path => '/api/conversations/$conversationId/read';
  @override
  String get method => 'POST';
  @override
  Map<String, dynamic> toJson() => {};
}
