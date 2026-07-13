class DriverModel {
  final int id;
  final String fullName;
  final String employeeId;
  final String badgeId;
  final String phone;
  final String email;
  final String licenseNumber;
  final String licenseExpiry;
  final String? photoUrl;
  final String status; // active / inactive

  const DriverModel({
    required this.id,
    required this.fullName,
    required this.employeeId,
    required this.badgeId,
    required this.phone,
    required this.email,
    required this.licenseNumber,
    required this.licenseExpiry,
    this.photoUrl,
    required this.status,
  });

  factory DriverModel.fromJson(Map<String, dynamic> j) => DriverModel(
    id:             j['id'] != null ? int.tryParse(j['id'].toString()) ?? 0 : 0,
    fullName:       j['full_name']?.toString() ?? '',
    employeeId:     j['employee_id']?.toString() ?? '',
    badgeId:        j['badge_id']?.toString() ?? '',
    phone:          j['phone']?.toString() ?? '',
    email:          j['email']?.toString() ?? '',
    licenseNumber:  j['license_number']?.toString() ?? '',
    licenseExpiry:  j['license_expiry']?.toString() ?? '',
    photoUrl:       j['photo_url']?.toString(),
    status:         j['status']?.toString() ?? 'active',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'employee_id': employeeId,
    'badge_id': badgeId,
    'phone': phone,
    'email': email,
    'license_number': licenseNumber,
    'license_expiry': licenseExpiry,
    'photo_url': photoUrl,
    'status': status,
  };

  DriverModel copyWith({
    String? fullName,
    String? phone,
    String? email,
    String? photoUrl,
  }) => DriverModel(
    id: id,
    fullName: fullName ?? this.fullName,
    employeeId: employeeId,
    badgeId: badgeId,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    licenseNumber: licenseNumber,
    licenseExpiry: licenseExpiry,
    photoUrl: photoUrl ?? this.photoUrl,
    status: status,
  );
}

class DriverStats {
  final int totalAssigned;
  final int preTripCompleted;
  final int postTripCompleted;
  final int pending;

  const DriverStats({
    required this.totalAssigned,
    required this.preTripCompleted,
    required this.postTripCompleted,
    required this.pending,
  });

  factory DriverStats.fromJson(Map<String, dynamic> j) => DriverStats(
    totalAssigned:    j['total_assigned'] ?? 0,
    preTripCompleted: j['pre_trip_completed'] ?? 0,
    postTripCompleted:j['post_trip_completed'] ?? 0,
    pending:          j['pending'] ?? 0,
  );

  factory DriverStats.empty() => const DriverStats(
    totalAssigned: 0, preTripCompleted: 0, postTripCompleted: 0, pending: 0,
  );
}
