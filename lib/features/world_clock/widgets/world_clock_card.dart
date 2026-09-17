import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/timezone/timezone_model.dart';
import '../../../core/timezone/timezone_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/world_clock_provider.dart';

class WorldClockCard extends ConsumerWidget {
  final TimezoneItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const WorldClockCard({
    super.key,
    required this.item,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currentTimeTickerProvider);
    final settings = ref.watch(settingsProvider);
    final deviceTz = ref.watch(deviceTimezoneProvider).value;

    final targetTime = TimezoneService.getCurrentTime(item.ianaId);
    final dayPeriod = TimezoneService.getDayPeriod(targetTime);
    final isDst = TimezoneService.isDst(item.ianaId);
    final offsetStr = TimezoneService.getFormattedOffset(item.ianaId);
    final diffStr = TimezoneService.getTimeDifferenceString(
      targetIanaId: item.ianaId,
      baseIanaId: deviceTz?.ianaId,
    );

    final timeFormat = settings.is24HourFormat
        ? (settings.showSeconds ? 'HH:mm:ss' : 'HH:mm')
        : (settings.showSeconds ? 'h:mm:ss' : 'h:mm');

    final timeString = DateFormat(timeFormat).format(targetTime);
    final periodString = settings.is24HourFormat
        ? ''
        : DateFormat('a').format(targetTime).toUpperCase();
    final dateString = DateFormat('EEE, MMM d').format(targetTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: dayPeriod.accentColor
              .withValues(alpha: context.isDark ? 0.2 : 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Flag, City, Country, and Day/Night Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            item.flagEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.cityName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: context.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.countryName,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: context.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Relative Time Diff Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: diffStr.startsWith('+')
                            ? AppColors.emeraldGreen
                                .withValues(alpha: context.isDark ? 0.15 : 0.12)
                            : (diffStr.startsWith('-')
                                ? AppColors.roseDusk.withValues(
                                    alpha: context.isDark ? 0.15 : 0.12)
                                : (context.isDark
                                    ? const Color(0xFF64748B)
                                        .withValues(alpha: 0.15)
                                    : const Color(0xFFE2E8F0))),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: diffStr.startsWith('+')
                              ? AppColors.emeraldGreen
                                  .withValues(alpha: context.isDark ? 0.3 : 0.5)
                              : (diffStr.startsWith('-')
                                  ? AppColors.roseDusk.withValues(
                                      alpha: context.isDark ? 0.3 : 0.5)
                                  : (context.isDark
                                      ? const Color(0xFF64748B)
                                          .withValues(alpha: 0.3)
                                      : const Color(0xFFCBD5E1))),
                        ),
                      ),
                      child: Text(
                        diffStr,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: diffStr.startsWith('+')
                              ? AppColors.emeraldGreen
                              : (diffStr.startsWith('-')
                                  ? AppColors.roseDusk
                                  : context.textMuted),
                        ),
                      ),
                    ),

                    if (onDelete != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: context.textMuted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
                        tooltip: 'Remove',
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 14),

                // Main Time row with Day/Night gradient accent
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          timeString,
                          style: GoogleFonts.outfit(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.0,
                            height: 1.0,
                            color: context.textPrimary,
                          ),
                        ),
                        if (periodString.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            periodString,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: dayPeriod.accentColor,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Day/Night indicator with icon
                    Row(
                      children: [
                        Icon(
                          dayPeriod.icon,
                          size: 16,
                          color: dayPeriod.accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dayPeriod.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: dayPeriod.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Bottom row: Date & Offset badge & DST badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateString,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          offsetStr,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: context.textMuted,
                          ),
                        ),
                        if (isDst) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.amberSun.withValues(
                                  alpha: context.isDark ? 0.15 : 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'DST',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amberSun,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
