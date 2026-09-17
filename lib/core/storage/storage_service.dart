import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/default_cities.dart';
import '../timezone/timezone_model.dart';
import '../../features/alarms/models/alarm_model.dart';

class StorageService {
  static const String _keyFavorites = 'saved_world_clocks';
  static const String _key24Hour = 'pref_24_hour_format';
  static const String _keyShowSeconds = 'pref_show_seconds';
  static const String _keyThemeMode = 'pref_theme_mode';
  static const String _keyConverterBase = 'pref_converter_base_zone';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // Favorites
  List<TimezoneItem> getFavorites() {
    final raw = _prefs.getStringList(_keyFavorites);
    if (raw == null || raw.isEmpty) {
      // First launch: initialize with curated default favorites
      saveFavorites(DefaultCities.initialFavorites);
      return DefaultCities.initialFavorites;
    }

    try {
      return raw.map((item) {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        return TimezoneItem.fromJson(decoded);
      }).toList();
    } catch (_) {
      return DefaultCities.initialFavorites;
    }
  }

  Future<bool> saveFavorites(List<TimezoneItem> items) {
    final encoded = items.map((item) => jsonEncode(item.toJson())).toList();
    return _prefs.setStringList(_keyFavorites, encoded);
  }

  // Preferences
  bool get is24HourFormat => _prefs.getBool(_key24Hour) ?? false;
  Future<bool> set24HourFormat(bool value) => _prefs.setBool(_key24Hour, value);

  bool get showSeconds => _prefs.getBool(_keyShowSeconds) ?? true;
  Future<bool> setShowSeconds(bool value) =>
      _prefs.setBool(_keyShowSeconds, value);

  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'dark';
  Future<bool> setThemeMode(String mode) =>
      _prefs.setString(_keyThemeMode, mode);

  String? get converterBaseZone => _prefs.getString(_keyConverterBase);
  Future<bool> setConverterBaseZone(String ianaId) =>
      _prefs.setString(_keyConverterBase, ianaId);

  // Alarms
  static const String _keyAlarms = 'saved_world_alarms';

  List<AlarmModel> getAlarms() {
    final raw = _prefs.getStringList(_keyAlarms);
    if (raw == null || raw.isEmpty) return [];
    try {
      return raw.map((item) {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        return AlarmModel.fromJson(decoded);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveAlarms(List<AlarmModel> alarms) {
    final encoded = alarms.map((item) => jsonEncode(item.toJson())).toList();
    return _prefs.setStringList(_keyAlarms, encoded);
  }
}
