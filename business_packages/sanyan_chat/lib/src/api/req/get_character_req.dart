import 'package:sanyan_network/sanyan_network.dart';

class GetCharacterReq extends BaseReq {
  final int id;

  GetCharacterReq({required this.id});

  @override
  String get path => '/api/characters/$id';
  @override
  String get method => 'GET';
  @override
  Map<String, dynamic> toJson() => {};
}
