import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimezoneDatabase {
  static bool _isInitialized = false;
  static String _localIanaId = 'UTC';

  static Future<void> initialize() async {
    if (!_isInitialized) {
      tz.initializeTimeZones();
      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        final String localTz = timezoneInfo.identifier;
        final loc = tz.getLocation(localTz);
        tz.setLocalLocation(loc);
        _localIanaId = localTz;
      } catch (e) {
        debugPrint('Could not detect device timezone: $e');
      }
      _isInitialized = true;
    }
  }

  static bool get isInitialized => _isInitialized;
  static String get localIanaId => _localIanaId;

  static tz.Location? getLocation(String ianaId) {
    try {
      return tz.getLocation(ianaId);
    } catch (_) {
      return null;
    }
  }

  static List<String> getAllAvailableLocations() {
    return tz.timeZoneDatabase.locations.keys.toList()..sort();
  }
}
