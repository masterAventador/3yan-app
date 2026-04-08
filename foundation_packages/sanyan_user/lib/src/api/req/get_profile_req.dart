import 'package:sanyan_network/sanyan_network.dart';

class GetProfileReq extends BaseReq {
  @override
  String get path => '/api/user/profile';
  @override
  String get method => 'GET';
  @override
  Map<String, dynamic> toJson() => {};
}
