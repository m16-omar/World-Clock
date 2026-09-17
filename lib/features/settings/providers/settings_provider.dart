import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be initialized in main');
});

class SettingsState {
  final bool is24HourFormat;
  final bool showSeconds;
  final ThemeMode themeMode;

  const SettingsState({
    required this.is24HourFormat,
    required this.showSeconds,
    required this.themeMode,
  });

  SettingsState copyWith({
    bool? is24HourFormat,
    bool? showSeconds,
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      is24HourFormat: is24HourFormat ?? this.is24HourFormat,
      showSeconds: showSeconds ?? this.showSeconds,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final storage = ref.watch(storageServiceProvider);
    return SettingsState(
      is24HourFormat: storage.is24HourFormat,
      showSeconds: storage.showSeconds,
      themeMode: _parseThemeMode(storage.themeMode),
    );
  }

  static ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark;
    }
  }

  void toggle24HourFormat() {
    final storage = ref.read(storageServiceProvider);
    final newValue = !state.is24HourFormat;
    state = state.copyWith(is24HourFormat: newValue);
    storage.set24HourFormat(newValue);
  }

  void toggleShowSeconds() {
    final storage = ref.read(storageServiceProvider);
    final newValue = !state.showSeconds;
    state = state.copyWith(showSeconds: newValue);
    storage.setShowSeconds(newValue);
  }

  void setThemeMode(ThemeMode mode) {
    final storage = ref.read(storageServiceProvider);
    state = state.copyWith(themeMode: mode);
    storage.setThemeMode(mode == ThemeMode.light ? 'light' : 'dark');
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
