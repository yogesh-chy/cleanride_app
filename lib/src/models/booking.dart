class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.washPackage,
    required this.timeSlot,
    required this.date,
    required this.status,
    this.assignedStaff,
    this.assignedStaffId,
    this.queuePosition,
    required this.createdAt,
    this.estimatedTime,
    required this.isPaid,
    this.contactPhone,
    this.address,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String vehicleType;
  final String vehicleNumber;
  final String washPackage;
  final String timeSlot;
  final String date;
  final String status;
  final String? assignedStaff;
  final String? assignedStaffId;
  final int? queuePosition;
  final String createdAt;
  final int? estimatedTime;
  final bool isPaid;
  final String? contactPhone;
  final String? address;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final customerObj = json['customer'];
    String parsedCustomerId = '';
    if (customerObj is Map) {
      parsedCustomerId = (customerObj['id'] ?? '').toString();
    } else if (customerObj != null) {
      parsedCustomerId = customerObj.toString();
    }

    // Safety fallback for assigned staff ID
    final staffObj = json['assigned_staff'];
    String? parsedStaffId;
    if (staffObj != null && staffObj.toString().isNotEmpty) {
      parsedStaffId = staffObj.toString();
    }

    return Booking(
      id: (json['id'] ?? '').toString(),
      customerId: parsedCustomerId,
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      vehicleType: json['vehicle_type'] as String? ?? 'car',
      vehicleNumber: json['vehicle_number'] as String? ?? '',
      washPackage: json['wash_package'] as String? ?? 'basic',
      timeSlot: json['time_slot'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'queued',
      assignedStaff: json['assigned_staff_name'] as String?,
      assignedStaffId: parsedStaffId,
      queuePosition: json['queue_position'] as int?,
      createdAt: json['created_at'] as String? ?? '',
      estimatedTime: json['estimated_time'] as int?,
      isPaid: json['is_paid'] as bool? ?? false,
      contactPhone: json['contact_phone'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_type': vehicleType,
      'vehicle_number': vehicleNumber,
      'wash_package': washPackage,
      'date': date,
      'time_slot': timeSlot,
      'contact_phone': contactPhone,
      'address': address,
    };
  }
}
