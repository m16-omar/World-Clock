class AlarmModel {
  final int id;
  final String title;
  final int hour;
  final int minute;
  final String ianaId;
  final String cityName;
  final String flagEmoji;
  final List<int> repeatDays; // 1 = Monday, 7 = Sunday. Empty = one-time
  final bool isEnabled;
  final bool vibrate;

  const AlarmModel({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    required this.ianaId,
    required this.cityName,
    required this.flagEmoji,
    this.repeatDays = const [],
    this.isEnabled = true,
    this.vibrate = true,
  });

  AlarmModel copyWith({
    int? id,
    String? title,
    int? hour,
    int? minute,
    String? ianaId,
    String? cityName,
    String? flagEmoji,
    List<int>? repeatDays,
    bool? isEnabled,
    bool? vibrate,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      title: title ?? this.title,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      ianaId: ianaId ?? this.ianaId,
      cityName: cityName ?? this.cityName,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
      vibrate: vibrate ?? this.vibrate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'hour': hour,
        'minute': minute,
        'ianaId': ianaId,
        'cityName': cityName,
        'flagEmoji': flagEmoji,
        'repeatDays': repeatDays,
        'isEnabled': isEnabled,
        'vibrate': vibrate,
      };

  factory AlarmModel.fromJson(Map<String, dynamic> json) => AlarmModel(
        id: json['id'] as int,
        title: json['title'] as String? ?? 'Alarm',
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        ianaId: json['ianaId'] as String? ?? 'UTC',
        cityName: json['cityName'] as String? ?? 'Local Time',
        flagEmoji: json['flagEmoji'] as String? ?? '⏰',
        repeatDays: (json['repeatDays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            const [],
        isEnabled: json['isEnabled'] as bool? ?? true,
        vibrate: json['vibrate'] as bool? ?? true,
      );

  String get repeatSummary {
    if (repeatDays.isEmpty) return 'Once';
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.length == 5 &&
        repeatDays.contains(1) &&
        repeatDays.contains(2) &&
        repeatDays.contains(3) &&
        repeatDays.contains(4) &&
        repeatDays.contains(5)) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 &&
        repeatDays.contains(6) &&
        repeatDays.contains(7)) {
      return 'Weekends';
    }

    const dayLabels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return repeatDays.map((d) => dayLabels[d] ?? '').join(', ');
  }
}
