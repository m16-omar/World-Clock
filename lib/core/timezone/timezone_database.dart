import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimezoneDatabase {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (!_isInitialized) {
      tz.initializeTimeZones();
      _isInitialized = true;
    }
  }

  static bool get isInitialized => _isInitialized;

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
