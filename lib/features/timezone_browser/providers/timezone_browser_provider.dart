import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/default_cities.dart';
import '../../../core/timezone/timezone_model.dart';

class SelectedContinentNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setContinent(String continent) => state = continent;
}

final selectedContinentProvider =
    NotifierProvider<SelectedContinentNotifier, String>(
        SelectedContinentNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final filteredTimezonesProvider = Provider<List<TimezoneItem>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final continent = ref.watch(selectedContinentProvider);

  return DefaultCities.allCities.where((item) {
    // Check continent filter
    if (continent != 'All' && item.continent != continent) {
      return false;
    }

    // Check search query
    if (query.isNotEmpty) {
      final cityMatch = item.cityName.toLowerCase().contains(query);
      final countryMatch = item.countryName.toLowerCase().contains(query);
      final ianaMatch = item.ianaId.toLowerCase().contains(query);
      return cityMatch || countryMatch || ianaMatch;
    }

    return true;
  }).toList();
});

final availableContinentsProvider = Provider<List<String>>((ref) {
  return const ['All', 'Africa', 'America', 'Europe', 'Asia', 'Oceania'];
});
