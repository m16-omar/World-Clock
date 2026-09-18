import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/default_cities.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/timezone/timezone_database.dart';
import '../../../core/timezone/timezone_service.dart';
import '../models/alarm_model.dart';

class EditAlarmSheet extends StatefulWidget {
  final AlarmModel? existingAlarm;
  final ValueChanged<AlarmModel> onSave;

  const EditAlarmSheet({
    super.key,
    this.existingAlarm,
    required this.onSave,
  });

  @override
  State<EditAlarmSheet> createState() => _EditAlarmSheetState();
}

class _EditAlarmSheetState extends State<EditAlarmSheet> {
  late TextEditingController _titleController;
  late int _selectedHour;
  late int _selectedMinute;
  late String _selectedIanaId;
  late String _selectedCityName;
  late String _selectedFlagEmoji;
  late List<int> _repeatDays;
  late bool _vibrate;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAlarm;
    if (existing != null) {
      _titleController = TextEditingController(text: existing.title);
      _selectedHour = existing.hour;
      _selectedMinute = existing.minute;
      _selectedIanaId = existing.ianaId;
      _selectedCityName = existing.cityName;
      _selectedFlagEmoji = existing.flagEmoji;
      _repeatDays = List.from(existing.repeatDays);
      _vibrate = existing.vibrate;
    } else {
      final now = DateTime.now();
      _titleController = TextEditingController(text: 'Wake up / Reminder');
      _selectedHour = (now.hour + 1) % 24;
      _selectedMinute = 0;
      _selectedIanaId = TimezoneDatabase.localIanaId;
      _selectedCityName = 'Local Device Time';
      _selectedFlagEmoji = '📍';
      _repeatDays = [];
      _vibrate = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
    );
    if (picked != null) {
      setState(() {
        _selectedHour = picked.hour;
        _selectedMinute = picked.minute;
      });
    }
  }

  void _pickLocation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceBg,
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
                    color: context.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Set Alarm for Timezone',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Text('📍', style: TextStyle(fontSize: 24)),
                  title: Text(
                    'Local Device Time',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Triggers at local time',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedIanaId = TimezoneDatabase.localIanaId;
                      _selectedCityName = 'Local Device Time';
                      _selectedFlagEmoji = '📍';
                    });
                    Navigator.of(ctx).pop();
                  },
                ),
                Divider(color: context.cardBorder),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: DefaultCities.allCities.length,
                    itemBuilder: (_, index) {
                      final city = DefaultCities.allCities[index];
                      final offset =
                          TimezoneService.getFormattedOffset(city.ianaId);

                      return ListTile(
                        leading: Text(
                          city.flagEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          city.cityName,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${city.countryName} • $offset',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedIanaId = city.ianaId;
                            _selectedCityName = city.cityName;
                            _selectedFlagEmoji = city.flagEmoji;
                          });
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

  void _toggleDay(int day) {
    setState(() {
      if (_repeatDays.contains(day)) {
        _repeatDays.remove(day);
      } else {
        _repeatDays.add(day);
        _repeatDays.sort();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hour12 = _selectedHour % 12 == 0 ? 12 : _selectedHour % 12;
    final period = _selectedHour >= 12 ? 'PM' : 'AM';
    final timeDisplay =
        '${hour12.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';

    const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: context.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingAlarm == null ? 'New Alarm' : 'Edit Alarm',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  color: context.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Big Time Selector
            Center(
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.shadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        timeDisplay,
                        style: GoogleFonts.outfit(
                          fontSize: 54,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.5,
                          height: 1.0,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        period,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: context.isDark
                              ? AppColors.cyanAccent
                              : AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.edit_rounded,
                        size: 20,
                        color: context.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title Input
            Text(
              'ALARM TITLE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.cardBorder),
              ),
              child: TextField(
                controller: _titleController,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: context.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. London Team Sync, Wake up',
                  hintStyle: TextStyle(color: context.textMuted),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: Icon(
                    Icons.label_outline_rounded,
                    color: context.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Timezone / Location Selector
            Text(
              'TIMEZONE LOCATION',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickLocation,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.inputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.cardBorder),
                ),
                child: Row(
                  children: [
                    Text(_selectedFlagEmoji,
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCityName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Repeat Options
            Text(
              'REPEAT DAYS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            // Day circles: Mon - Sun (1 to 7)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final dayNumber = index + 1;
                final isSelected = _repeatDays.contains(dayNumber);

                return InkWell(
                  onTap: () => _toggleDay(dayNumber),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primaryBlue
                          : context.inputBg,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : context.cardBorder,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        dayNames[index],
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            // Quick Preset Chips
            Wrap(
              spacing: 8,
              children: [
                _PresetChip(
                  label: 'Every day',
                  onTap: () => setState(
                      () => _repeatDays = [1, 2, 3, 4, 5, 6, 7]),
                ),
                _PresetChip(
                  label: 'Weekdays',
                  onTap: () =>
                      setState(() => _repeatDays = [1, 2, 3, 4, 5]),
                ),
                _PresetChip(
                  label: 'Weekends',
                  onTap: () => setState(() => _repeatDays = [6, 7]),
                ),
                _PresetChip(
                  label: 'Once (No repeat)',
                  onTap: () => setState(() => _repeatDays = []),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Vibrate Switch
            Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.cardBorder),
              ),
              child: SwitchListTile(
                title: Text(
                  'Vibration',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                value: _vibrate,
                activeTrackColor: AppColors.primaryBlue,
                activeThumbColor: Colors.white,
                inactiveTrackColor: context.inputBg,
                inactiveThumbColor: context.textMuted,
                onChanged: (val) => setState(() => _vibrate = val),
              ),
            ),

            const SizedBox(height: 28),

            // Save Alarm Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  final id = widget.existingAlarm?.id ??
                      DateTime.now().millisecondsSinceEpoch % 100000;
                  final alarm = AlarmModel(
                    id: id,
                    title: _titleController.text.trim().isEmpty
                        ? 'Alarm'
                        : _titleController.text.trim(),
                    hour: _selectedHour,
                    minute: _selectedMinute,
                    ianaId: _selectedIanaId,
                    cityName: _selectedCityName,
                    flagEmoji: _selectedFlagEmoji,
                    repeatDays: _repeatDays,
                    isEnabled: true,
                    vibrate: _vibrate,
                  );
                  widget.onSave(alarm);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.existingAlarm == null
                      ? 'Create Alarm'
                      : 'Save Changes',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        color: context.textSecondary,
      ),
      backgroundColor: context.cardBg,
      side: BorderSide(color: context.cardBorder),
      onPressed: onTap,
    );
  }
}
