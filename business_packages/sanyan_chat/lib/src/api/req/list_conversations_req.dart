import 'package:sanyan_network/sanyan_network.dart';

class ListConversationsReq extends BaseReq {
  @override
  String get path => '/api/conversations';
  @override
  String get method => 'GET';
  @override
  Map<String, dynamic> toJson() => {};
}
