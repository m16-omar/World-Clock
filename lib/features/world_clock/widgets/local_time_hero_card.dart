import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/timezone/timezone_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/world_clock_provider.dart';

class LocalTimeHeroCard extends ConsumerWidget {
  const LocalTimeHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch 1-second ticker to re-render smoothly
    ref.watch(currentTimeTickerProvider);
    final deviceTzAsync = ref.watch(deviceTimezoneProvider);
    final settings = ref.watch(settingsProvider);

    final deviceTz = deviceTzAsync.value;
    final ianaId = deviceTz?.ianaId ?? 'UTC';
    final currentTime = TimezoneService.getCurrentTime(ianaId);

    final dayPeriod = TimezoneService.getDayPeriod(currentTime);
    final isDst = TimezoneService.isDst(ianaId);
    final offsetStr = TimezoneService.getFormattedOffset(ianaId);

    final timeFormat = settings.is24HourFormat
        ? (settings.showSeconds ? 'HH:mm:ss' : 'HH:mm')
        : (settings.showSeconds ? 'h:mm:ss' : 'h:mm');

    final timeString = DateFormat(timeFormat).format(currentTime);
    final periodString = settings.is24HourFormat
        ? ''
        : DateFormat('a').format(currentTime).toUpperCase();
    final dateString = DateFormat('EEEE, MMMM d, y').format(currentTime);

    final isDark = context.isDark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            dayPeriod.accentColor.withValues(alpha: isDark ? 0.22 : 0.25),
            isDark ? AppColors.darkSurface : Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: dayPeriod.accentColor.withValues(alpha: isDark ? 0.35 : 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: dayPeriod.accentColor.withValues(alpha: isDark ? 0.15 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Location + Day Period Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: dayPeriod.accentColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        size: 18,
                        color: dayPeriod.accentColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deviceTz?.cityName ?? 'Current Location',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          'Your Local Time',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Day/Night indicator pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: dayPeriod.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: dayPeriod.accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dayPeriod.emoji,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        dayPeriod.label,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: dayPeriod.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Time digits with luxury typography
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  timeString,
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                    height: 1.0,
                    color: context.textPrimary,
                  ),
                ),
                if (periodString.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    periodString,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: dayPeriod.accentColor,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // Date string
            Text(
              dateString,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.textSecondary,
              ),
            ),

            const SizedBox(height: 14),

            // Badges row: UTC Offset + DST status + Timezone ID
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Badge(
                  label: offsetStr,
                  icon: Icons.public_rounded,
                  color: const Color(0xFF38BDF8),
                ),
                if (isDst)
                  const _Badge(
                    label: 'DST Active',
                    icon: Icons.light_mode_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                _Badge(
                  label: ianaId,
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFFA78BFA),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.12 : 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: context.isDark ? 0.3 : 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
