import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:world_time/core/storage/storage_service.dart';
import 'package:world_time/core/timezone/timezone_database.dart';
import 'package:world_time/core/timezone/timezone_service.dart';
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
    });
  });
}
