import 'package:get_storage/get_storage.dart';

class LocalStorage {
  static late GetStorage _box;

  static Future<void> init() async {
    await GetStorage.init();
    _box = GetStorage();
  }

  static String? get token => _box.read('token');
  static set token(String? value) {
    if (value == null) {
      _box.remove('token');
    } else {
      _box.write('token', value);
    }
  }

  static int? get userId => _box.read('userId');
  static set userId(int? value) {
    if (value == null) {
      _box.remove('userId');
    } else {
      _box.write('userId', value);
    }
  }

  static String? get lastInputMode => _box.read('lastInputMode');
  static set lastInputMode(String? value) {
    if (value == null) {
      _box.remove('lastInputMode');
    } else {
      _box.write('lastInputMode', value);
    }
  }

  static void clear() {
    _box.erase();
  }
}
