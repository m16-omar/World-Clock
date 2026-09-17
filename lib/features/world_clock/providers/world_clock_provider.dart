import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../../core/constants/default_cities.dart';
import '../../../core/timezone/timezone_model.dart';
import '../../settings/providers/settings_provider.dart';

/// Periodic stream emitting current DateTime every second
final currentTimeTickerProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

/// Detects device's local IANA timezone
final deviceTimezoneProvider = FutureProvider<TimezoneItem>((ref) async {
  try {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    final String localTz = timezoneInfo.identifier;

    // Try to match with existing known city
    final match = DefaultCities.allCities.cast<TimezoneItem?>().firstWhere(
          (c) => c?.ianaId.toLowerCase() == localTz.toLowerCase(),
          orElse: () => null,
        );

    if (match != null) {
      return match;
    }

    // Parse city name from IANA ID (e.g. "Africa/Lagos" -> "Lagos")
    final parts = localTz.split('/');
    final continent = parts.isNotEmpty ? parts[0] : 'Local';
    final city = parts.length > 1
        ? parts[1].replaceAll('_', ' ')
        : localTz.replaceAll('_', ' ');

    return TimezoneItem(
      ianaId: localTz,
      cityName: city,
      countryName: continent,
      countryCode: '',
      flagEmoji: '📍',
      continent: continent,
    );
  } catch (_) {
    // Fallback to initial favorite city
    return DefaultCities.initialFavorites.first;
  }
});

/// Notifier for saved / favorite world clock locations
class FavoritesNotifier extends Notifier<List<TimezoneItem>> {
  @override
  List<TimezoneItem> build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.getFavorites();
  }

  bool isFavorite(String ianaId) {
    return state.any((c) => c.ianaId == ianaId);
  }

  void addFavorite(TimezoneItem item) {
    if (!isFavorite(item.ianaId)) {
      final storage = ref.read(storageServiceProvider);
      final updated = [...state, item];
      state = updated;
      storage.saveFavorites(updated);
    }
  }

  void removeFavorite(String ianaId) {
    final storage = ref.read(storageServiceProvider);
    final updated = state.where((c) => c.ianaId != ianaId).toList();
    state = updated;
    storage.saveFavorites(updated);
  }

  void toggleFavorite(TimezoneItem item) {
    if (isFavorite(item.ianaId)) {
      removeFavorite(item.ianaId);
    } else {
      addFavorite(item);
    }
  }

  void reorder(int oldIndex, int newIndex) {
    final storage = ref.read(storageServiceProvider);
    final list = [...state];
    int adjustedNewIndex = newIndex;
    if (adjustedNewIndex > oldIndex) adjustedNewIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(adjustedNewIndex, item);
    state = list;
    storage.saveFavorites(list);
  }

  void resetToDefaults() {
    final storage = ref.read(storageServiceProvider);
    state = DefaultCities.initialFavorites;
    storage.saveFavorites(DefaultCities.initialFavorites);
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<TimezoneItem>>(
  FavoritesNotifier.new,
);
