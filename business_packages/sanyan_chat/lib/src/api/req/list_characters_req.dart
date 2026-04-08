import 'package:sanyan_network/sanyan_network.dart';

class ListCharactersReq extends BaseReq {
  @override
  String get path => '/api/characters';
  @override
  String get method => 'GET';
  @override
  Map<String, dynamic> toJson() => {};
}
