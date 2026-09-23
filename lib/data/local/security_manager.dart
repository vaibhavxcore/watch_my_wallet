import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityManager {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'database_encryption_key';

  static Future<String> getDatabaseKey() async {
    String? key = await _storage.read(key: _keyName);
    if (key == null) {
      key = _generateSecureKey();
      await _storage.write(key: _keyName, value: key);
    }
    return key;
  }

  static String _generateSecureKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  static Future<void> clearKey() async {
    await _storage.delete(key: _keyName);
  }
}
