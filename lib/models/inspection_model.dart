class QrData {
  final String qrCodeString;
  final String vehicleNumber;
  final String? trailerNumber;
  final String? vin;
  final String? plateNumber;
  final String? fleetNumber;
  final String companyName;
  final String driverName;
  final String employeeId;
  final String? inspectionType; // 'pre_trip' | 'post_trip' | null (driver selects)

  const QrData({
    required this.qrCodeString,
    required this.vehicleNumber,
    this.trailerNumber,
    this.vin,
    this.plateNumber,
    this.fleetNumber,
    required this.companyName,
    required this.driverName,
    required this.employeeId,
    this.inspectionType,
  });

  factory QrData.fromJson(Map<String, dynamic> j) => QrData(
    qrCodeString:  j['qr_code_string'] ?? '',
    vehicleNumber: j['vehicle_number'] ?? '',
    trailerNumber: j['trailer_number'],
    vin:           j['vin'],
    plateNumber:   j['plate_number'],
    fleetNumber:   j['fleet_number'],
    companyName:   j['company_name'] ?? '',
    driverName:    j['driver_name'] ?? '',
    employeeId:    j['employee_id'] ?? '',
    inspectionType:j['inspection_type'],
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
}

class InspectionSubmission {
  final String qrCodeString;
  final String inspectionType; // 'pre_trip' | 'post_trip'
  final List<ChecklistResponse> responses;
  final List<DefectReport> defects;
  final String? additionalNotes;
  final GpsLocation gpsLocation;
  final DateTime startedAt;

  const InspectionSubmission({
    required this.qrCodeString,
    required this.inspectionType,
    required this.responses,
    this.defects = const [],
    this.additionalNotes,
    required this.gpsLocation,
    required this.startedAt,
  });

  Map<String, dynamic> toJson() => {
    'qr_code_string': qrCodeString,
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
  final int id;
  final String inspectionId; // display ID e.g. FC-2024-0001
  final String vehicleNumber;
  final String inspectionType;
  final DateTime submittedAt;
  final GpsLocation? gpsLocation;
  final String status;

  const InspectionResult({
    required this.id,
    required this.inspectionId,
    required this.vehicleNumber,
    required this.inspectionType,
    required this.submittedAt,
    this.gpsLocation,
    required this.status,
  });

  factory InspectionResult.fromJson(Map<String, dynamic> j) => InspectionResult(
    id:             j['id'] as int,
    inspectionId:   j['inspection_id'] ?? 'FC-${j['id']}',
    vehicleNumber:  j['vehicle_number'] ?? '',
    inspectionType: j['inspection_type'] ?? '',
    submittedAt:    DateTime.tryParse(j['submitted_at'] ?? '') ?? DateTime.now(),
    status:         j['status'] ?? 'completed',
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
    id:          j['id'] as int,
    title:       j['title'] ?? '',
    message:     j['message'] ?? '',
    type:        j['type'] ?? 'management',
    isRead:      j['is_read'] == 1 || j['is_read'] == true,
    createdAt:   DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
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
    inspectionId:  j['inspection_id'] ?? '',
    vehicleNumber: j['vehicle_number'] ?? '',
    type:          j['inspection_type'] ?? '',
    status:        j['status'] ?? '',
    date:          DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
  );
}
