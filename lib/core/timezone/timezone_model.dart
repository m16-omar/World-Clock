class TimezoneItem {
  final String ianaId;
  final String cityName;
  final String countryName;
  final String countryCode;
  final String flagEmoji;
  final String continent;

  const TimezoneItem({
    required this.ianaId,
    required this.cityName,
    required this.countryName,
    required this.countryCode,
    required this.flagEmoji,
    required this.continent,
  });

  Map<String, dynamic> toJson() => {
        'ianaId': ianaId,
        'cityName': cityName,
        'countryName': countryName,
        'countryCode': countryCode,
        'flagEmoji': flagEmoji,
        'continent': continent,
      };

  factory TimezoneItem.fromJson(Map<String, dynamic> json) => TimezoneItem(
        ianaId: json['ianaId'] as String,
        cityName: json['cityName'] as String,
        countryName: json['countryName'] as String,
        countryCode: json['countryCode'] as String? ?? '',
        flagEmoji: json['flagEmoji'] as String? ?? '🌍',
        continent: json['continent'] as String? ?? 'Global',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimezoneItem &&
          runtimeType == other.runtimeType &&
          ianaId == other.ianaId;

  @override
  int get hashCode => ianaId.hashCode;
}
