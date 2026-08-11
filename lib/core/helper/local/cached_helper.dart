import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static late SharedPreferences sharedPreferences;

  static init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  static Future<bool> saveData({
    required String key,
    required dynamic value,
  }) async {
    if (value is String) return await sharedPreferences.setString(key, value);
    if (value is bool) return await sharedPreferences.setBool(key, value);
    if (value is int) return await sharedPreferences.setInt(key, value);
    return await sharedPreferences.setDouble(key, value);
  }

  static dynamic getData({required String key}) {
    return sharedPreferences.get(key);
  }

  static Future<bool> removeData({required String key}) async {
    return await sharedPreferences.remove(key);
  }

  /// Stores any JSON-encodable value (e.g. a list of maps) under [key].
  static Future<bool> saveJson({required String key, required dynamic value}) {
    return sharedPreferences.setString(key, jsonEncode(value));
  }

  /// Reads back a value stored via [saveJson], or `null` if absent.
  static dynamic getJson({required String key}) {
    final raw = sharedPreferences.getString(key);
    return raw == null ? null : jsonDecode(raw);
  }
}
