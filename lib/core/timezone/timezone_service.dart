import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../theme/app_theme.dart';
import 'timezone_database.dart';

enum TimeDayPeriod {
  morning,
  afternoon,
  evening,
  night,
}

extension TimeDayPeriodExtension on TimeDayPeriod {
  String get label {
    switch (this) {
      case TimeDayPeriod.morning:
        return 'Morning';
      case TimeDayPeriod.afternoon:
        return 'Afternoon';
      case TimeDayPeriod.evening:
        return 'Evening';
      case TimeDayPeriod.night:
        return 'Night';
    }
  }

  String get emoji {
    switch (this) {
      case TimeDayPeriod.morning:
        return '🌅';
      case TimeDayPeriod.afternoon:
        return '☀️';
      case TimeDayPeriod.evening:
        return '🌇';
      case TimeDayPeriod.night:
        return '🌙';
    }
  }

  IconData get icon {
    switch (this) {
      case TimeDayPeriod.morning:
        return Icons.wb_twilight_rounded;
      case TimeDayPeriod.afternoon:
        return Icons.wb_sunny_rounded;
      case TimeDayPeriod.evening:
        return Icons.nights_stay_outlined;
      case TimeDayPeriod.night:
        return Icons.bedtime_rounded;
    }
  }

  LinearGradient get gradient {
    switch (this) {
      case TimeDayPeriod.morning:
        return AppColors.morningGradient;
      case TimeDayPeriod.afternoon:
        return AppColors.dayGradient;
      case TimeDayPeriod.evening:
        return AppColors.eveningGradient;
      case TimeDayPeriod.night:
        return AppColors.nightGradient;
    }
  }

  Color get accentColor {
    switch (this) {
      case TimeDayPeriod.morning:
        return const Color(0xFFFF9A3C);
      case TimeDayPeriod.afternoon:
        return const Color(0xFF38BDF8);
      case TimeDayPeriod.evening:
        return const Color(0xFFF43F5E);
      case TimeDayPeriod.night:
        return const Color(0xFF818CF8);
    }
  }
}

class TimezoneService {
  /// Returns the current time in the specified IANA timezone
  static tz.TZDateTime getCurrentTime(String ianaId) {
    final location = TimezoneDatabase.getLocation(ianaId) ?? tz.local;
    return tz.TZDateTime.now(location);
  }

  /// Calculates the time in a target timezone for a given UTC or local date/time
  static tz.TZDateTime getTimeAt(String ianaId, DateTime dateTime) {
    final location = TimezoneDatabase.getLocation(ianaId) ?? tz.local;
    return tz.TZDateTime.from(dateTime, location);
  }

  /// Converts a specified date/time from one timezone to another offline
  static tz.TZDateTime convertTime({
    required DateTime sourceDateTime,
    required String fromIanaId,
    required String toIanaId,
  }) {
    final fromLocation = TimezoneDatabase.getLocation(fromIanaId) ?? tz.local;
    final toLocation = TimezoneDatabase.getLocation(toIanaId) ?? tz.local;

    // Construct TZDateTime in the source location
    final sourceTz = tz.TZDateTime(
      fromLocation,
      sourceDateTime.year,
      sourceDateTime.month,
      sourceDateTime.day,
      sourceDateTime.hour,
      sourceDateTime.minute,
      sourceDateTime.second,
    );

    // Convert to target location
    return tz.TZDateTime.from(sourceTz, toLocation);
  }

  /// Returns whether Daylight Saving Time is active for the location at given time
  static bool isDst(String ianaId, {DateTime? at}) {
    final location = TimezoneDatabase.getLocation(ianaId);
    if (location == null) return false;
    final time = at != null
        ? tz.TZDateTime.from(at, location)
        : tz.TZDateTime.now(location);
    return time.timeZone.isDst;
  }

  /// Returns formatted UTC offset like "UTC+1", "UTC-5", or "UTC+5:30"
  static String getFormattedOffset(String ianaId, {DateTime? at}) {
    final location = TimezoneDatabase.getLocation(ianaId);
    if (location == null) return 'UTC';

    final time = at != null
        ? tz.TZDateTime.from(at, location)
        : tz.TZDateTime.now(location);

    final offsetMs = time.timeZoneOffset.inMilliseconds;
    final totalMinutes = offsetMs ~/ 60000;
    final hours = totalMinutes ~/ 60;
    final minutes = (totalMinutes % 60).abs();

    final sign = hours >= 0 ? '+' : '-';
    final absHours = hours.abs();

    if (minutes == 0) {
      return 'UTC$sign$absHours';
    } else {
      final formattedMins = minutes.toString().padLeft(2, '0');
      return 'UTC$sign$absHours:$formattedMins';
    }
  }

  /// Formatted relative offset difference from local device or base timezone
  static String getTimeDifferenceString({
    required String targetIanaId,
    String? baseIanaId,
    DateTime? at,
  }) {
    final targetLoc = TimezoneDatabase.getLocation(targetIanaId) ?? tz.local;
    final baseLoc = baseIanaId != null
        ? (TimezoneDatabase.getLocation(baseIanaId) ?? tz.local)
        : tz.local;

    final targetTime = at != null
        ? tz.TZDateTime.from(at, targetLoc)
        : tz.TZDateTime.now(targetLoc);
    final baseTime = at != null
        ? tz.TZDateTime.from(at, baseLoc)
        : tz.TZDateTime.now(baseLoc);

    final diffMinutes =
        (targetTime.timeZoneOffset - baseTime.timeZoneOffset).inMinutes;

    if (diffMinutes == 0) {
      return 'Same time';
    }

    final hours = diffMinutes ~/ 60;
    final minutes = (diffMinutes % 60).abs();
    final sign = diffMinutes > 0 ? '+' : '-';
    final absHours = hours.abs();

    if (minutes == 0) {
      return '$sign$absHours hrs';
    } else {
      return '$sign$absHours h ${minutes}m';
    }
  }

  /// Categorizes local time into Morning, Afternoon, Evening, or Night
  static TimeDayPeriod getDayPeriod(DateTime localTime) {
    final hour = localTime.hour;
    if (hour >= 5 && hour < 12) {
      return TimeDayPeriod.morning;
    } else if (hour >= 12 && hour < 17) {
      return TimeDayPeriod.afternoon;
    } else if (hour >= 17 && hour < 21) {
      return TimeDayPeriod.evening;
    } else {
      return TimeDayPeriod.night;
    }
  }

  /// Returns whether a given hour (0-23) is within standard business/working hours (9am - 5pm)
  static bool isBusinessHours(int hour) {
    return hour >= 9 && hour < 17;
  }
}
