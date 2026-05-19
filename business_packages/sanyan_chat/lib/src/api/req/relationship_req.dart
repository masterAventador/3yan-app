import 'package:sanyan_network/sanyan_network.dart';
import '../models/relationship.dart';

/// GET /api/relationships/me 请求。
class FetchMyRelationshipReq extends BaseReq {
  @override
  String get path => '/api/relationships/me';

  @override
  String get method => 'GET';

  @override
  Map<String, dynamic> toJson() => {};
}

/// GET /api/relationships/me 响应数据。
class FetchMyRelationshipData {
  final Relationship relationship;

  const FetchMyRelationshipData(this.relationship);

  factory FetchMyRelationshipData.fromJson(Map<String, dynamic> json) =>
      FetchMyRelationshipData(Relationship.fromJson(json));
}
