class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.time,
    required this.available,
    this.occupancyReason,
  });

  final String id;
  final String time;
  final bool available;
  final String? occupancyReason;

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: (json['id'] ?? '').toString(),
      time: json['time'] as String? ?? '',
      available: json['available'] as bool? ?? false,
      occupancyReason: json['occupancy_reason'] as String?,
    );
  }
}
