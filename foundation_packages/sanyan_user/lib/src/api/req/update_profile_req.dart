import 'package:sanyan_network/sanyan_network.dart';

class UpdateProfileReq extends BaseReq {
  final String? nickname;
  final String? avatar;

  UpdateProfileReq({this.nickname, this.avatar});

  @override
  String get path => '/api/user/profile';
  @override
  String get method => 'PUT';
  @override
  Map<String, dynamic> toJson() => {'nickname': nickname, 'avatar': avatar};
}
