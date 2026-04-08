import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? get token => _prefs.getString('token');
  static set token(String? value) {
    if (value == null) {
      _prefs.remove('token');
    } else {
      _prefs.setString('token', value);
    }
  }

  static int? get userId => _prefs.getInt('userId');
  static set userId(int? value) {
    if (value == null) {
      _prefs.remove('userId');
    } else {
      _prefs.setInt('userId', value);
    }
  }

  static void clear() {
    _prefs.clear();
  }
}
