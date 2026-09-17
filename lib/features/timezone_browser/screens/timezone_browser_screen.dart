import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/timezone/timezone_model.dart';
import '../../../core/timezone/timezone_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../../world_clock/providers/world_clock_provider.dart';
import '../providers/timezone_browser_provider.dart';

class TimezoneBrowserScreen extends ConsumerStatefulWidget {
  const TimezoneBrowserScreen({super.key});

  @override
  ConsumerState<TimezoneBrowserScreen> createState() =>
      _TimezoneBrowserScreenState();
}

class _TimezoneBrowserScreenState extends ConsumerState<TimezoneBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = ref.watch(filteredTimezonesProvider);
    final continents = ref.watch(availableContinentsProvider);
    final selectedContinent = ref.watch(selectedContinentProvider);
    final favorites = ref.watch(favoritesProvider);
    final favoritesNotifier = ref.read(favoritesProvider.notifier);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Location'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(fontSize: 15),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).setQuery(val);
                },
                decoration: InputDecoration(
                  hintText: 'Search city, country, or timezone...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).setQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // Continent Filter Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: continents.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final continent = continents[index];
                final isSelected = continent == selectedContinent;

                return ChoiceChip(
                  label: Text(continent),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(selectedContinentProvider.notifier)
                          .setContinent(continent);
                    }
                  },
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  ),
                  selectedColor: AppColors.primaryBlue,
                  backgroundColor: AppColors.darkCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : AppColors.darkCardBorder,
                    ),
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // List of Timezones
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final isSaved =
                          favorites.any((f) => f.ianaId == item.ianaId);

                      // Calculate current time in this zone
                      final time = TimezoneService.getCurrentTime(item.ianaId);
                      final offsetStr =
                          TimezoneService.getFormattedOffset(item.ianaId);
                      final timeStr = DateFormat(
                        settings.is24HourFormat ? 'HH:mm' : 'h:mm a',
                      ).format(time);

                      return _TimezoneListTile(
                        item: item,
                        isSaved: isSaved,
                        timeStr: timeStr,
                        offsetStr: offsetStr,
                        onToggleFavorite: () {
                          favoritesNotifier.toggleFavorite(item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.travel_explore_rounded,
            size: 56,
            color: Color(0xFF475569),
          ),
          const SizedBox(height: 16),
          Text(
            'No locations found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try searching for another city or country',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimezoneListTile extends StatelessWidget {
  final TimezoneItem item;
  final bool isSaved;
  final String timeStr;
  final String offsetStr;
  final VoidCallback onToggleFavorite;

  const _TimezoneListTile({
    required this.item,
    required this.isSaved,
    required this.timeStr,
    required this.offsetStr,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSaved
              ? AppColors.primaryBlue.withValues(alpha: 0.4)
              : AppColors.darkCardBorder,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Text(
          item.flagEmoji,
          style: const TextStyle(fontSize: 26),
        ),
        title: Text(
          item.cityName,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${item.countryName} • $offsetStr',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF94A3B8),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeStr,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isSaved ? Icons.check_circle_rounded : Icons.add_circle_outline,
                color: isSaved ? AppColors.emeraldGreen : AppColors.primaryBlue,
                size: 24,
              ),
              onPressed: onToggleFavorite,
              tooltip: isSaved ? 'Remove from Clocks' : 'Add to Clocks',
            ),
          ],
        ),
      ),
    );
  }
}
