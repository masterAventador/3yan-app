import 'package:sanyan_network/sanyan_network.dart';

class ListMessagesReq extends BaseReq {
  final int? beforeId;
  final int limit;

  ListMessagesReq({this.beforeId, this.limit = 20});

  @override
  String get path => '/api/messages';
  @override
  String get method => 'GET';
  @override
  Map<String, dynamic> toJson() => {'beforeId': beforeId, 'limit': limit};
}
