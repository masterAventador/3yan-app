import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/character.dart';

class CharacterApi {
  static final _client = ApiClient();

  static Future<ApiResponse<List<Character>>> list() =>
      _client.get(
        '/api/characters',
        fromData: (d) => (d as List).map((e) => Character.fromJson(e)).toList(),
      );

  static Future<ApiResponse<Character>> detail(int id) =>
      _client.get('/api/characters/$id', fromData: (d) => Character.fromJson(d));
}
