import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../core/notifications/notification_service.dart';
import '../../../core/timezone/timezone_database.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/alarm_model.dart';

class AlarmNotifier extends Notifier<List<AlarmModel>> {
  @override
  List<AlarmModel> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getAlarms();
  }

  Future<void> addAlarm(AlarmModel alarm) async {
    final storage = ref.read(storageServiceProvider);
    final updated = [...state, alarm];
    state = updated;
    await storage.saveAlarms(updated);

    if (alarm.isEnabled) {
      await NotificationService.instance.scheduleAlarm(alarm);
    }
  }

  Future<void> updateAlarm(AlarmModel alarm) async {
    final storage = ref.read(storageServiceProvider);
    final updated = state.map((a) => a.id == alarm.id ? alarm : a).toList();
    state = updated;
    await storage.saveAlarms(updated);

    if (alarm.isEnabled) {
      await NotificationService.instance.scheduleAlarm(alarm);
    } else {
      await NotificationService.instance.cancelAlarm(alarm.id);
    }
  }

  Future<void> toggleAlarm(int id) async {
    final storage = ref.read(storageServiceProvider);
    final updated = state.map((a) {
      if (a.id == id) {
        final toggled = a.copyWith(isEnabled: !a.isEnabled);
        if (toggled.isEnabled) {
          NotificationService.instance.scheduleAlarm(toggled);
        } else {
          NotificationService.instance.cancelAlarm(toggled.id);
        }
        return toggled;
      }
      return a;
    }).toList();

    state = updated;
    await storage.saveAlarms(updated);
  }

  Future<void> deleteAlarm(int id) async {
    final storage = ref.read(storageServiceProvider);
    final updated = state.where((a) => a.id != id).toList();
    state = updated;
    await storage.saveAlarms(updated);
    await NotificationService.instance.cancelAlarm(id);
  }
}

final alarmProvider =
    NotifierProvider<AlarmNotifier, List<AlarmModel>>(AlarmNotifier.new);

/// Finds the next upcoming alarm and returns human-friendly remaining time
final nextUpcomingAlarmProvider = Provider<String?>((ref) {
  final alarms = ref.watch(alarmProvider).where((a) => a.isEnabled).toList();
  if (alarms.isEmpty) return null;

  DateTime? earliestTrigger;
  AlarmModel? nextAlarm;

  final nowUtc = DateTime.now().toUtc();

  for (final alarm in alarms) {
    final loc = TimezoneDatabase.getLocation(alarm.ianaId) ?? tz.local;
    final nowInZone = tz.TZDateTime.now(loc);

    var scheduled = tz.TZDateTime(
      loc,
      nowInZone.year,
      nowInZone.month,
      nowInZone.day,
      alarm.hour,
      alarm.minute,
    );

    if (scheduled.isBefore(nowInZone)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final triggerUtc = scheduled.toUtc();
    if (earliestTrigger == null || triggerUtc.isBefore(earliestTrigger)) {
      earliestTrigger = triggerUtc;
      nextAlarm = alarm;
    }
  }

  if (earliestTrigger == null || nextAlarm == null) return null;

  final diff = earliestTrigger.difference(nowUtc);
  if (diff.isNegative) return null;

  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;

  if (hours == 0 && minutes == 0) {
    return 'Next alarm rings in less than a minute';
  } else if (hours == 0) {
    return 'Next alarm rings in $minutes min (${nextAlarm.title})';
  } else {
    return 'Next alarm rings in $hours hr ${minutes}m (${nextAlarm.cityName})';
  }
});
