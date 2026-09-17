import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/theme_toggle_switch.dart';
import '../../settings/providers/settings_provider.dart';
import '../../timezone_browser/screens/timezone_browser_screen.dart';
import '../providers/world_clock_provider.dart';
import '../widgets/local_time_hero_card.dart';
import '../widgets/world_clock_card.dart';

class WorldClockScreen extends ConsumerWidget {
  const WorldClockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final favoritesNotifier = ref.read(favoritesProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.cyanAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.public_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'World Time',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          // Light / Dark Mode Pill Toggle
          ThemeToggleSwitch(
            width: 48,
            height: 28,
            isDark: settings.themeMode == ThemeMode.dark,
            onChanged: (isDark) {
              settingsNotifier.setThemeMode(
                isDark ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
          const SizedBox(width: 8),

          // 12H / 24H Toggle
          ActionChip(
            label: Text(settings.is24HourFormat ? '24H' : '12H'),
            labelStyle: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryBlue,
            ),
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
            side: BorderSide(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
            ),
            onPressed: () => settingsNotifier.toggle24HourFormat(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 26),
            tooltip: 'Add Location',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TimezoneBrowserScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Prominent Local Device Time Hero Card
                        const LocalTimeHeroCard(),

                        const SizedBox(height: 24),

                        // Section Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'World Clocks (${favorites.length})',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (favorites.isEmpty)
                              TextButton(
                                onPressed: () =>
                                    favoritesNotifier.resetToDefaults(),
                                child: const Text('Restore Defaults'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                // List of Saved Clocks
                if (favorites.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(context, favoritesNotifier),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = favorites[index];
                          return WorldClockCard(
                            key: ValueKey(item.ianaId),
                            item: item,
                            onDelete: () {
                              favoritesNotifier.removeFavorite(item.ianaId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Removed ${item.cityName}'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () =>
                                        favoritesNotifier.addFavorite(item),
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                          );
                        },
                        childCount: favorites.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TimezoneBrowserScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: Text(
          'Add City',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, FavoritesNotifier favoritesNotifier) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.cardBorder),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              size: 48,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 16),
            Text(
              'No clocks added yet',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add locations from around the world to track their live time offline.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TimezoneBrowserScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text('Browse Cities'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => favoritesNotifier.resetToDefaults(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textPrimary,
                    side: BorderSide(color: context.cardBorder),
                  ),
                  child: const Text('Restore Defaults'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
