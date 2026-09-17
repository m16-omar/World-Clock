import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_time/core/storage/storage_service.dart';
import 'package:world_time/core/timezone/timezone_database.dart';
import 'package:world_time/core/timezone/timezone_service.dart';
import 'package:world_time/features/alarms/models/alarm_model.dart';
import 'package:world_time/features/settings/providers/settings_provider.dart';
import 'package:world_time/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await TimezoneDatabase.initialize();
  });

  group('Timezone Engine Offline Tests', () {
    test('IANA Database initializes offline with full locations', () {
      expect(TimezoneDatabase.isInitialized, isTrue);
      final locations = TimezoneDatabase.getAllAvailableLocations();
      expect(locations.isNotEmpty, isTrue);
      expect(locations.contains('Africa/Lagos'), isTrue);
      expect(locations.contains('America/New_York'), isTrue);
      expect(locations.contains('Europe/London'), isTrue);
      expect(locations.contains('Asia/Tokyo'), isTrue);
    });

    test('Converts time offline between Lagos and New York', () {
      // Lagos (UTC+1) at Jan 1, 2027 14:00 (winter, NY is EST UTC-5)
      // Difference is 6 hours, so NY should be 08:00
      final lagosTime = DateTime(2027, 1, 1, 14, 0, 0);
      final nyTime = TimezoneService.convertTime(
        sourceDateTime: lagosTime,
        fromIanaId: 'Africa/Lagos',
        toIanaId: 'America/New_York',
      );

      expect(nyTime.hour, equals(8));
      expect(nyTime.minute, equals(0));
      expect(nyTime.day, equals(1));
      expect(nyTime.year, equals(2027));
    });

    test('Calculates daylight saving time transitions correctly', () {
      // New York winter (Jan 1) -> EST (no DST)
      final winter = DateTime(2026, 1, 1, 12, 0);
      expect(TimezoneService.isDst('America/New_York', at: winter), isFalse);

      // New York summer (July 1) -> EDT (DST active)
      final summer = DateTime(2026, 7, 1, 12, 0);
      expect(TimezoneService.isDst('America/New_York', at: summer), isTrue);
    });

    test('Formats UTC offset strings properly', () {
      final lagosOffset = TimezoneService.getFormattedOffset('Africa/Lagos');
      expect(lagosOffset, equals('UTC+1'));
    });

    test('Calculates relative time differences', () {
      final diff = TimezoneService.getTimeDifferenceString(
        targetIanaId: 'Asia/Tokyo',
        baseIanaId: 'Europe/London',
        at: DateTime(2026, 1, 1, 12, 0), // London UTC+0, Tokyo UTC+9
      );
      expect(diff, equals('+9 hrs'));
    });

    test('Categorizes TimeDayPeriod correctly', () {
      expect(
        TimezoneService.getDayPeriod(DateTime(2026, 1, 1, 8, 0)),
        equals(TimeDayPeriod.morning),
      );
      expect(
        TimezoneService.getDayPeriod(DateTime(2026, 1, 1, 14, 0)),
        equals(TimeDayPeriod.afternoon),
      );
      expect(
        TimezoneService.getDayPeriod(DateTime(2026, 1, 1, 19, 0)),
        equals(TimeDayPeriod.evening),
      );
      expect(
        TimezoneService.getDayPeriod(DateTime(2026, 1, 1, 23, 0)),
        equals(TimeDayPeriod.night),
      );
    });
  });

  group('Storage and App Smoke Tests', () {
    testWidgets('WorldTimeApp builds and renders correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
          ],
          child: const WorldTimeApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar title exists
      expect(find.text('World Time'), findsWidgets);

      // Verify header and cities appear
      expect(find.text('World Clocks (6)'), findsOneWidget);
      expect(find.text('Lagos'), findsOneWidget);
      expect(find.text('New York'), findsOneWidget);

      // Verify Alarms tab icon exists and switch to it
      expect(find.byIcon(Icons.alarm_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.alarm_rounded));
      await tester.pumpAndSettle();

      // Verify World Alarms screen is active
      expect(find.text('World Alarms'), findsOneWidget);
      expect(find.text('Set Alarm'), findsOneWidget);
    });
  });

  group('Alarm Engine and Persistence Tests', () {
    test('AlarmModel serializes and deserializes correctly', () {
      const alarm = AlarmModel(
        id: 101,
        title: 'Tokyo Standup',
        hour: 9,
        minute: 30,
        ianaId: 'Asia/Tokyo',
        cityName: 'Tokyo',
        flagEmoji: '🇯🇵',
        repeatDays: [1, 2, 3, 4, 5],
        isEnabled: true,
        vibrate: true,
      );

      final json = alarm.toJson();
      final fromJson = AlarmModel.fromJson(json);

      expect(fromJson.id, equals(101));
      expect(fromJson.title, equals('Tokyo Standup'));
      expect(fromJson.hour, equals(9));
      expect(fromJson.minute, equals(30));
      expect(fromJson.ianaId, equals('Asia/Tokyo'));
      expect(fromJson.cityName, equals('Tokyo'));
      expect(fromJson.flagEmoji, equals('🇯🇵'));
      expect(fromJson.repeatDays, equals([1, 2, 3, 4, 5]));
      expect(fromJson.repeatSummary, equals('Weekdays'));
      expect(fromJson.isEnabled, isTrue);
      expect(fromJson.vibrate, isTrue);
    });

    test('AlarmModel repeat summary calculates presets correctly', () {
      const once = AlarmModel(
        id: 1,
        title: 'One-off',
        hour: 8,
        minute: 0,
        ianaId: 'UTC',
        cityName: 'Local',
        flagEmoji: '📍',
        repeatDays: [],
      );
      expect(once.repeatSummary, equals('Once'));

      final everyday = once.copyWith(repeatDays: [1, 2, 3, 4, 5, 6, 7]);
      expect(everyday.repeatSummary, equals('Every day'));

      final weekend = once.copyWith(repeatDays: [6, 7]);
      expect(weekend.repeatSummary, equals('Weekends'));

      final customDays = once.copyWith(repeatDays: [1, 3, 5]);
      expect(customDays.repeatSummary, equals('Mon, Wed, Fri'));
    });

    test('StorageService saves and retrieves alarms accurately', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();

      expect(storage.getAlarms(), isEmpty);

      const alarm1 = AlarmModel(
        id: 201,
        title: 'London Sync',
        hour: 14,
        minute: 0,
        ianaId: 'Europe/London',
        cityName: 'London',
        flagEmoji: '🇬🇧',
      );

      await storage.saveAlarms([alarm1]);

      final retrieved = storage.getAlarms();
      expect(retrieved.length, equals(1));
      expect(retrieved.first.id, equals(201));
      expect(retrieved.first.cityName, equals('London'));
    });
  });
}
