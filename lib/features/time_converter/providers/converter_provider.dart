import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/default_cities.dart';
import '../../../core/timezone/timezone_model.dart';

class ConverterState {
  final TimezoneItem baseZone;
  final DateTime selectedDateTime;
  final List<TimezoneItem> targetZones;

  const ConverterState({
    required this.baseZone,
    required this.selectedDateTime,
    required this.targetZones,
  });

  ConverterState copyWith({
    TimezoneItem? baseZone,
    DateTime? selectedDateTime,
    List<TimezoneItem>? targetZones,
  }) {
    return ConverterState(
      baseZone: baseZone ?? this.baseZone,
      selectedDateTime: selectedDateTime ?? this.selectedDateTime,
      targetZones: targetZones ?? this.targetZones,
    );
  }
}

class ConverterNotifier extends Notifier<ConverterState> {
  @override
  ConverterState build() {
    return ConverterState(
      baseZone: DefaultCities.initialFavorites.first,
      selectedDateTime: DateTime.now(),
      targetZones: DefaultCities.initialFavorites.sublist(1),
    );
  }

  void setBaseZone(TimezoneItem zone) {
    state = state.copyWith(baseZone: zone);
  }

  void setDate(DateTime date) {
    final current = state.selectedDateTime;
    final updated = DateTime(
      date.year,
      date.month,
      date.day,
      current.hour,
      current.minute,
      current.second,
    );
    state = state.copyWith(selectedDateTime: updated);
  }

  void setTime(TimeOfDay time) {
    final current = state.selectedDateTime;
    final updated = DateTime(
      current.year,
      current.month,
      current.day,
      time.hour,
      time.minute,
    );
    state = state.copyWith(selectedDateTime: updated);
  }

  void setHour(int hour) {
    final current = state.selectedDateTime;
    final updated = DateTime(
      current.year,
      current.month,
      current.day,
      hour,
      current.minute,
    );
    state = state.copyWith(selectedDateTime: updated);
  }

  void resetToNow() {
    state = state.copyWith(selectedDateTime: DateTime.now());
  }

  void addTargetZone(TimezoneItem zone) {
    if (!state.targetZones.any((z) => z.ianaId == zone.ianaId)) {
      state = state.copyWith(targetZones: [...state.targetZones, zone]);
    }
  }

  void removeTargetZone(String ianaId) {
    state = state.copyWith(
      targetZones:
          state.targetZones.where((z) => z.ianaId != ianaId).toList(),
    );
  }

  void swapBaseWithTarget(TimezoneItem newBase) {
    final oldBase = state.baseZone;
    final updatedTargets =
        state.targetZones.where((z) => z.ianaId != newBase.ianaId).toList();
    updatedTargets.insert(0, oldBase);
    state = state.copyWith(
      baseZone: newBase,
      targetZones: updatedTargets,
    );
  }
}

final converterProvider =
    NotifierProvider<ConverterNotifier, ConverterState>(ConverterNotifier.new);
