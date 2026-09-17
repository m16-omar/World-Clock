import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/default_cities.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/timezone/timezone_model.dart';
import '../../../core/timezone/timezone_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/converter_provider.dart';

class TimeConverterScreen extends ConsumerWidget {
  const TimeConverterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(converterProvider);
    final notifier = ref.read(converterProvider.notifier);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset to Now',
            onPressed: () => notifier.resetToNow(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Base Zone & Time Selection Card
            _BaseZoneCard(
              state: state,
              is24Hour: settings.is24HourFormat,
              onSelectBaseZone: (zone) => notifier.setBaseZone(zone),
              onDateTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: state.selectedDateTime,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2050),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: AppColors.primaryBlue,
                          surface: AppColors.darkCard,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  notifier.setDate(pickedDate);
                }
              },
              onTimeTap: () async {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(state.selectedDateTime),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: AppColors.primaryBlue,
                          surface: AppColors.darkCard,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedTime != null) {
                  notifier.setTime(pickedTime);
                }
              },
            ),

            const SizedBox(height: 16),

            // 24-Hour Quick Scrubber Slider
            _HourScrubber(
              selectedHour: state.selectedDateTime.hour,
              onHourChanged: (hour) => notifier.setHour(hour),
            ),

            const SizedBox(height: 20),

            // Header for Comparisons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Converted Timezones (${state.targetZones.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddTargetSheet(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add City'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Target comparisons list
            if (state.targetZones.isEmpty)
              _buildEmptyTargets(context, ref)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.targetZones.length,
                itemBuilder: (context, index) {
                  final target = state.targetZones[index];
                  final converted = TimezoneService.convertTime(
                    sourceDateTime: state.selectedDateTime,
                    fromIanaId: state.baseZone.ianaId,
                    toIanaId: target.ianaId,
                  );

                  return _ConvertedCityCard(
                    target: target,
                    convertedTime: converted,
                    baseZone: state.baseZone,
                    is24Hour: settings.is24HourFormat,
                    onSwap: () => notifier.swapBaseWithTarget(target),
                    onDelete: () => notifier.removeTargetZone(target.ianaId),
                  );
                },
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTargets(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.compare_arrows_rounded,
                size: 44, color: Color(0xFF475569)),
            const SizedBox(height: 12),
            Text(
              'No target timezones added',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddTargetSheet(context, ref),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Cities to Compare'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTargetSheet(BuildContext context, WidgetRef ref) {
    final targets = ref.read(converterProvider).targetZones;
    final base = ref.read(converterProvider).baseZone;
    final notifier = ref.read(converterProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Add Comparison City',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: DefaultCities.allCities.length,
                    itemBuilder: (_, index) {
                      final item = DefaultCities.allCities[index];
                      final isBase = item.ianaId == base.ianaId;
                      final isAlreadyTarget =
                          targets.any((t) => t.ianaId == item.ianaId);

                      return ListTile(
                        leading: Text(
                          item.flagEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          item.cityName,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${item.countryName} • ${TimezoneService.getFormattedOffset(item.ianaId)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        trailing: isBase
                            ? const Chip(
                                label: Text('Base'),
                                padding: EdgeInsets.zero,
                              )
                            : Icon(
                                isAlreadyTarget
                                    ? Icons.check_circle_rounded
                                    : Icons.add_circle_outline_rounded,
                                color: isAlreadyTarget
                                    ? AppColors.emeraldGreen
                                    : AppColors.primaryBlue,
                              ),
                        onTap: isBase
                            ? null
                            : () {
                                if (isAlreadyTarget) {
                                  notifier.removeTargetZone(item.ianaId);
                                } else {
                                  notifier.addTargetZone(item);
                                }
                                Navigator.of(ctx).pop();
                              },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _BaseZoneCard extends StatelessWidget {
  final ConverterState state;
  final bool is24Hour;
  final ValueChanged<TimezoneItem> onSelectBaseZone;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  const _BaseZoneCard({
    required this.state,
    required this.is24Hour,
    required this.onSelectBaseZone,
    required this.onDateTap,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final offsetStr =
        TimezoneService.getFormattedOffset(state.baseZone.ianaId);
    final isDst = TimezoneService.isDst(
      state.baseZone.ianaId,
      at: state.selectedDateTime,
    );
    final dayPeriod = TimezoneService.getDayPeriod(state.selectedDateTime);

    final timeString = DateFormat(
      is24Hour ? 'HH:mm' : 'h:mm a',
    ).format(state.selectedDateTime);
    final dateString =
        DateFormat('EEEE, MMM d, y').format(state.selectedDateTime);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Base Zone Dropdown / Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SOURCE LOCATION',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.primaryBlue,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: dayPeriod.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(dayPeriod.emoji, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      dayPeriod.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: dayPeriod.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // City selector button
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showBaseCityPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Row(
                children: [
                  Text(
                    state.baseZone.flagEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.baseZone.cityName,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${state.baseZone.countryName} ($offsetStr${isDst ? ' • DST' : ''})',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.unfold_more_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Date & Time pickers row
          Row(
            children: [
              // Date picker button
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onDateTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.darkCardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateString,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Time picker button
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTimeTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.darkCardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: AppColors.cyanAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            timeString,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBaseCityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select Base Location',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: DefaultCities.allCities.length,
                    itemBuilder: (_, index) {
                      final item = DefaultCities.allCities[index];
                      final isSelected = item.ianaId == state.baseZone.ianaId;

                      return ListTile(
                        leading: Text(
                          item.flagEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          item.cityName,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${item.countryName} • ${TimezoneService.getFormattedOffset(item.ianaId)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: AppColors.primaryBlue)
                            : null,
                        onTap: () {
                          onSelectBaseZone(item);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HourScrubber extends StatelessWidget {
  final int selectedHour;
  final ValueChanged<int> onHourChanged;

  const _HourScrubber({
    required this.selectedHour,
    required this.onHourChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '24-Hour Timeline Scrubber',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Text(
                '${selectedHour.toString().padLeft(2, '0')}:00',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyanAccent,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: AppColors.cyanAccent,
              inactiveTrackColor: AppColors.darkSurface,
              thumbColor: Colors.white,
              overlayColor: AppColors.cyanAccent.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: selectedHour.toDouble(),
              min: 0,
              max: 23,
              divisions: 23,
              onChanged: (val) {
                onHourChanged(val.round());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConvertedCityCard extends StatelessWidget {
  final TimezoneItem target;
  final DateTime convertedTime;
  final TimezoneItem baseZone;
  final bool is24Hour;
  final VoidCallback onSwap;
  final VoidCallback onDelete;

  const _ConvertedCityCard({
    required this.target,
    required this.convertedTime,
    required this.baseZone,
    required this.is24Hour,
    required this.onSwap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dayPeriod = TimezoneService.getDayPeriod(convertedTime);
    final isDst = TimezoneService.isDst(target.ianaId, at: convertedTime);
    final offsetStr =
        TimezoneService.getFormattedOffset(target.ianaId, at: convertedTime);
    final isBusiness = TimezoneService.isBusinessHours(convertedTime.hour);
    final diffStr = TimezoneService.getTimeDifferenceString(
      targetIanaId: target.ianaId,
      baseIanaId: baseZone.ianaId,
      at: convertedTime,
    );

    final timeString = DateFormat(
      is24Hour ? 'HH:mm' : 'h:mm a',
    ).format(convertedTime);
    final dateString = DateFormat('EEE, MMM d').format(convertedTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dayPeriod.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Flag, City, Working hours pill, actions
          Row(
            children: [
              Text(
                target.flagEmoji,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.cityName,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${target.countryName} • $offsetStr',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              // Business Hours Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isBusiness
                      ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                      : const Color(0xFF64748B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isBusiness
                        ? AppColors.emeraldGreen.withValues(alpha: 0.3)
                        : const Color(0xFF64748B).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBusiness ? Icons.work_rounded : Icons.nightlight_round,
                      size: 11,
                      color: isBusiness
                          ? AppColors.emeraldGreen
                          : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isBusiness ? 'Work Hours' : 'Off Hours',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isBusiness
                            ? AppColors.emeraldGreen
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),
              // Swap as Base button
              IconButton(
                icon: const Icon(Icons.swap_vert_rounded, size: 20),
                tooltip: 'Set as Base',
                onPressed: onSwap,
                color: const Color(0xFF94A3B8),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
              // Remove button
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Remove',
                onPressed: onDelete,
                color: const Color(0xFF64748B),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Row 2: Converted Time & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                timeString,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              Row(
                children: [
                  Text(
                    dayPeriod.emoji,
                    style: const TextStyle(fontSize: 13),
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

          const SizedBox(height: 6),

          // Row 3: Converted Date, Diff pill & Copy button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateString,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: diffStr.startsWith('+')
                          ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                          : (diffStr.startsWith('-')
                              ? AppColors.roseDusk.withValues(alpha: 0.15)
                              : const Color(0xFF64748B)
                                  .withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(6),
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
                                : const Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  if (isDst) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.amberSun.withValues(alpha: 0.15),
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
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      Clipboard.setData(ClipboardData(
                        text:
                            '${target.cityName}: $timeString on $dateString ($offsetStr)',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied ${target.cityName} time!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
