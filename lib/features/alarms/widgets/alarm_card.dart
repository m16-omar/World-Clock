import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/timezone/timezone_service.dart';
import '../models/alarm_model.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final bool is24Hour;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.is24Hour,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final offsetStr = TimezoneService.getFormattedOffset(alarm.ianaId);

    // Format time display
    final String timeStr;
    final String periodStr;

    if (is24Hour) {
      timeStr =
          '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
      periodStr = '';
    } else {
      final hour12 = alarm.hour % 12 == 0 ? 12 : alarm.hour % 12;
      timeStr =
          '${hour12.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
      periodStr = alarm.hour >= 12 ? 'PM' : 'AM';
    }

    final activeColor =
        alarm.isEnabled ? AppColors.primaryBlue : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: alarm.isEnabled
              ? AppColors.primaryBlue.withValues(alpha: 0.3)
              : AppColors.darkCardBorder,
          width: 1.2,
        ),
        boxShadow: alarm.isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
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
                // Top Row: Title + Timezone & Toggle Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alarm.title.isEmpty ? 'Alarm' : alarm.title,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: alarm.isEnabled
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                alarm.flagEmoji,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${alarm.cityName} ($offsetStr)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: alarm.isEnabled,
                      activeTrackColor: AppColors.primaryBlue,
                      activeThumbColor: Colors.white,
                      inactiveTrackColor: AppColors.darkSurface,
                      inactiveThumbColor: const Color(0xFF64748B),
                      onChanged: onToggle,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Main Time digits
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      timeStr,
                      style: GoogleFonts.outfit(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                        height: 1.0,
                        color: alarm.isEnabled
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                    if (periodStr.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        periodStr,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: activeColor,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom Row: Repeat chips + delete action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: alarm.isEnabled
                            ? AppColors.primaryBlue.withValues(alpha: 0.12)
                            : const Color(0xFF334155).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: alarm.isEnabled
                              ? AppColors.primaryBlue.withValues(alpha: 0.25)
                              : AppColors.darkCardBorder,
                        ),
                      ),
                      child: Text(
                        alarm.repeatSummary,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: alarm.isEnabled
                              ? AppColors.cyanAccent
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: const Color(0xFF64748B),
                      onPressed: onDelete,
                      tooltip: 'Delete Alarm',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
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
