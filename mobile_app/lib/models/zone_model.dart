class Zone {
  final int zoneId;
  final String zoneName;
  final String zoneType;
  final String? description;
  final bool isActive;

  const Zone({
    required this.zoneId,
    required this.zoneName,
    required this.zoneType,
    this.description,
    required this.isActive,
  });

  factory Zone.fromJson(Map<String, dynamic> json) => Zone(
    zoneId: json['zone_id'] ?? 0,
    zoneName: json['zone_name'] ?? '',
    zoneType: json['zone_type'] ?? '',
    description: json['description'],
    isActive: json['is_active'] ?? true,
  );
}
