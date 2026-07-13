class QrData {
  final String  qrCodeString;
  final int?    vehicleId;          // DB id of the vehicle — needed for submission
  final String  vehicleNumber;
  final String? trailerNumber;
  final String? vin;
  final String? plateNumber;
  final String? fleetNumber;
  final String  companyName;
  final String  driverName;
  final String  employeeId;
  final String? inspectionType;       // 'pre_trip' | 'post_trip' | null (driver selects)
  final int?    pendingInspectionId;  // DB id of the pending inspection job (if assigned)
  final String? pendingInspectionRef; // Human-readable inspection_id (e.g. INS-260701...)

  const QrData({
    required this.qrCodeString,
    this.vehicleId,
    required this.vehicleNumber,
    this.trailerNumber,
    this.vin,
    this.plateNumber,
    this.fleetNumber,
    required this.companyName,
    required this.driverName,
    required this.employeeId,
    this.inspectionType,
    this.pendingInspectionId,
    this.pendingInspectionRef,
  });

  /// Whether the admin has pre-assigned a specific inspection job for this scan.
  bool get hasAssignedJob => pendingInspectionId != null && inspectionType != null;

  factory QrData.fromJson(Map<String, dynamic> j) => QrData(
    qrCodeString:        j['qr_code_string']?.toString() ?? '',
    vehicleId:           j['vehicle_id'] != null ? int.tryParse(j['vehicle_id'].toString()) : null,
    vehicleNumber:       j['vehicle_number']?.toString() ?? '',
    trailerNumber:       j['trailer_number']?.toString(),
    vin:                 j['vin']?.toString(),
    plateNumber:         j['plate_number']?.toString(),
    fleetNumber:         j['fleet_number']?.toString(),
    companyName:         j['company_name']?.toString() ?? '',
    driverName:          j['driver_name']?.toString() ?? '',
    employeeId:          j['employee_id']?.toString() ?? '',
    inspectionType:      j['inspection_type']?.toString(),
    pendingInspectionId: j['pending_inspection_id'] != null
        ? int.tryParse(j['pending_inspection_id'].toString())
        : null,
    pendingInspectionRef: j['pending_inspection_ref']?.toString(),
  );
}

class ChecklistResponse {
  final String itemId;
  final String sectionId;
  final String itemLabel;
  final String? selectedOption; // 'Good','Defective','Available','Not Available','Yes','No'

  const ChecklistResponse({
    required this.itemId,
    required this.sectionId,
    required this.itemLabel,
    this.selectedOption,
  });

  bool get isComplete => selectedOption != null;

  ChecklistResponse copyWith({String? selectedOption}) => ChecklistResponse(
    itemId: itemId,
    sectionId: sectionId,
    itemLabel: itemLabel,
    selectedOption: selectedOption ?? this.selectedOption,
  );

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'section_id': sectionId,
    'item_label': itemLabel,
    'selected_option': selectedOption,
  };
}

class DefectReport {
  final String category;
  final String severity;
  final String description;

  const DefectReport({
    required this.category,
    required this.severity,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'severity': severity,
    'description': description,
  };
}

class GpsLocation {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime capturedAt;

  const GpsLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'captured_at': capturedAt.toIso8601String(),
  };

  factory GpsLocation.fromJson(Map<String, dynamic> j) => GpsLocation(
    latitude:   double.tryParse(j['latitude'].toString()) ?? 0,
    longitude:  double.tryParse(j['longitude'].toString()) ?? 0,
    address:    j['address']?.toString() ?? '',
    capturedAt: DateTime.tryParse(j['captured_at']?.toString() ?? '') ?? DateTime.now(),
  );
}

class InspectionSubmission {
  final String qrCodeString;
  final String vehicleNumber;
  final String? trailerNumber;
  final String inspectionType; // 'pre_trip' | 'post_trip'
  final List<ChecklistResponse> responses;
  final List<DefectReport> defects;
  final String? additionalNotes;
  final GpsLocation gpsLocation;
  final DateTime startedAt;

  const InspectionSubmission({
    required this.qrCodeString,
    this.vehicleNumber = '',
    this.trailerNumber,
    required this.inspectionType,
    required this.responses,
    this.defects = const [],
    this.additionalNotes,
    required this.gpsLocation,
    required this.startedAt,
  });

  Map<String, dynamic> toJson() => {
    'qr_code_string': qrCodeString,
    'vehicle_number': vehicleNumber,
    'trailer_number': trailerNumber,
    'inspection_type': inspectionType,
    'responses': responses.map((r) => r.toJson()).toList(),
    'defects': defects.map((d) => d.toJson()).toList(),
    'additional_notes': additionalNotes,
    'gps_location': gpsLocation.toJson(),
    'started_at': startedAt.toIso8601String(),
  };

  int get totalItems    => responses.length;
  int get passedItems   => responses.where((r) => r.selectedOption == 'Good' || r.selectedOption == 'Available').length;
  int get defectCount   => responses.where((r) =>
      r.selectedOption == 'Defective' || r.selectedOption == 'Not Available' || r.selectedOption == 'Yes').length;
}

class InspectionResult {
  final int    id;
  final String inspectionId;
  final String vehicleNumber;
  final String inspectionType;
  final DateTime assignDate;    // created_at — when admin assigned the job
  final DateTime? submittedAt;  // null until driver submits
  final GpsLocation? gpsLocation;
  final String status;

  const InspectionResult({
    required this.id,
    required this.inspectionId,
    required this.vehicleNumber,
    required this.inspectionType,
    required this.assignDate,
    this.submittedAt,
    this.gpsLocation,
    required this.status,
  });

  // Display date: submitted_at when completed, created_at for pending
  DateTime get displayDate => submittedAt ?? assignDate;

  factory InspectionResult.fromJson(Map<String, dynamic> j) => InspectionResult(
    id:             j['id'] != null ? int.tryParse(j['id'].toString()) ?? 0 : 0,
    inspectionId:   j['inspection_id']?.toString() ?? '',
    vehicleNumber:  j['vehicle_number']?.toString() ?? '',
    inspectionType: j['inspection_type']?.toString() ?? '',
    // Use created_at as the assign date; fall back to 'date' field the API sends
    assignDate:     DateTime.tryParse(
                      j['created_at']?.toString() ??
                      j['date']?.toString() ?? '') ?? DateTime.now(),
    submittedAt:    j['submitted_at'] != null
                      ? DateTime.tryParse(j['submitted_at'].toString())
                      : null,
    gpsLocation:    j['gps_location'] != null
                      ? GpsLocation.fromJson(j['gps_location'] as Map<String, dynamic>)
                      : null,
    status:         j['status']?.toString() ?? 'pending',
  );
}

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type; // 'new_assignment' | 'reminder' | 'management'
  final bool isRead;
  final DateTime createdAt;
  final String? referenceId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.referenceId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
    id:          j['id'] != null ? int.tryParse(j['id'].toString()) ?? 0 : 0,
    title:       j['title']?.toString() ?? '',
    message:     j['message']?.toString() ?? '',
    type:        j['type']?.toString() ?? 'management',
    isRead:      j['is_read'] == 1 || j['is_read'] == true,
    createdAt:   DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
    referenceId: j['reference_id']?.toString(),
  );
}

class ActivityItem {
  final String inspectionId;
  final String vehicleNumber;
  final String type;
  final String status;
  final DateTime date;

  const ActivityItem({
    required this.inspectionId,
    required this.vehicleNumber,
    required this.type,
    required this.status,
    required this.date,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> j) => ActivityItem(
    inspectionId:  j['inspection_id']?.toString() ?? '',
    vehicleNumber: j['vehicle_number']?.toString() ?? '',
    type:          j['inspection_type']?.toString() ?? '',
    status:        j['status']?.toString() ?? '',
    date:          DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
  );
}
