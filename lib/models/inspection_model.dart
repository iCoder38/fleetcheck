// lib/models/inspection_model.dart
// Updated for:
//   Feature 1 — Auto-assign (pending_inspection_id always present after scan)
//   Feature 2 — Custom checklists (checklist_sections from API, not hardcoded)
//   Feature 3 — Post-trip default (post_trip_forced flag from scan response)

// ─── Checklist data structures ────────────────────────────────────────────────

class ChecklistTemplateItem {
  final int    id;
  final String label;
  final String responseType; // good_defective | available_not_available | yes_no | pass_fail | text | number
  final bool   isRequired;
  final bool   isDotMandatory;
  final int    sortOrder;
  final List<String> options; // derived from responseType

  const ChecklistTemplateItem({
    required this.id,
    required this.label,
    required this.responseType,
    required this.isRequired,
    required this.isDotMandatory,
    required this.sortOrder,
    required this.options,
  });

  factory ChecklistTemplateItem.fromJson(Map<String, dynamic> j) {
    final rt = j['response_type']?.toString() ?? 'good_defective';
    return ChecklistTemplateItem(
      id:             j['id'] != null ? int.tryParse(j['id'].toString()) ?? 0 : 0,
      label:          j['label']?.toString() ?? '',
      responseType:   rt,
      isRequired:     j['is_required'] == true || j['is_required'] == 1,
      isDotMandatory: j['is_dot_mandatory'] == true || j['is_dot_mandatory'] == 1,
      sortOrder:      j['sort_order'] != null ? int.tryParse(j['sort_order'].toString()) ?? 0 : 0,
      options:        _optionsFromType(rt, j['options']),
    );
  }

  static List<String> _optionsFromType(String type, dynamic apiOptions) {
    // Use API-provided options if present
    if (apiOptions is List && apiOptions.isNotEmpty) {
      return apiOptions.map((e) => e.toString()).toList();
    }
    // Derive from response_type
    switch (type) {
      case 'good_defective':          return ['Good', 'Defective'];
      case 'available_not_available': return ['Available', 'Not Available'];
      case 'yes_no':                  return ['Yes', 'No'];
      case 'pass_fail':               return ['Pass', 'Fail'];
      default:                        return ['Good', 'Defective'];
    }
  }

  bool get isTextInput   => responseType == 'text';
  bool get isNumberInput => responseType == 'number';
  bool get isSelectInput => !isTextInput && !isNumberInput;

  // Maps display option back to DB-storable value
  String optionToResponse(String option) {
    switch (option.toLowerCase()) {
      case 'good':          return 'good';
      case 'defective':     return 'defective';
      case 'available':     return 'available';
      case 'not available': return 'not_available';
      case 'yes':           return 'yes';
      case 'no':            return 'no';
      case 'pass':          return 'good';
      case 'fail':          return 'defective';
      default:              return option.toLowerCase().replaceAll(' ', '_');
    }
  }
}

class ChecklistTemplateSection {
  final int    id;
  final String title;
  final int    sortOrder;
  final bool   isNotesSection;
  final List<ChecklistTemplateItem> items;

  const ChecklistTemplateSection({
    required this.id,
    required this.title,
    required this.sortOrder,
    required this.isNotesSection,
    required this.items,
  });

  factory ChecklistTemplateSection.fromJson(Map<String, dynamic> j) {
    final itemsRaw = j['items'];
    final items = (itemsRaw is List)
        ? itemsRaw
            .whereType<Map<String, dynamic>>()
            .map(ChecklistTemplateItem.fromJson)
            .toList()
        : <ChecklistTemplateItem>[];
    return ChecklistTemplateSection(
      id:             j['id'] != null ? int.tryParse(j['id'].toString()) ?? 0 : 0,
      title:          j['title']?.toString() ?? '',
      sortOrder:      j['sort_order'] != null ? int.tryParse(j['sort_order'].toString()) ?? 0 : 0,
      isNotesSection: j['is_notes_section'] == true || j['is_notes_section'] == 1,
      items:          items,
    );
  }

  bool get hasItems => !isNotesSection && items.isNotEmpty;
  int  get totalItems => isNotesSection ? 0 : items.length;
}

// ─── QR Scan result ───────────────────────────────────────────────────────────

class QrData {
  final String  qrCodeString;
  final int?    vehicleId;
  final String  vehicleNumber;
  final String? vehicleType;
  final String? trailerNumber;
  final String? vin;
  final String? plateNumber;
  final String? fleetNumber;
  final String  companyName;
  final String  driverName;
  final String  employeeId;
  final String? driverPhone;
  // Job context
  final String?              inspectionType;       // pre_trip | post_trip — auto-set by server
  final int?                 pendingInspectionId;
  final String?              pendingInspectionRef;
  final int?                 templateId;
  final bool                 postTripForced;       // Feature 3: server forced post-trip
  // Feature 2: full checklist from API (dynamic, not hardcoded)
  final List<ChecklistTemplateSection> checklistSections;

  const QrData({
    required this.qrCodeString,
    this.vehicleId,
    required this.vehicleNumber,
    this.vehicleType,
    this.trailerNumber,
    this.vin,
    this.plateNumber,
    this.fleetNumber,
    required this.companyName,
    required this.driverName,
    required this.employeeId,
    this.driverPhone,
    this.inspectionType,
    this.pendingInspectionId,
    this.pendingInspectionRef,
    this.templateId,
    this.postTripForced = false,
    this.checklistSections = const [],
  });

  /// True when the server has a pending job ready for this driver.
  /// After Feature 1 (auto-assign), this is ALWAYS true after a successful scan.
  bool get hasAssignedJob =>
      pendingInspectionId != null && inspectionType != null;

  factory QrData.fromJson(Map<String, dynamic> j) {
    // Parse checklist sections from scan response
    final sectionsRaw = j['checklist_sections'];
    final sections = (sectionsRaw is List)
        ? sectionsRaw
            .whereType<Map<String, dynamic>>()
            .map(ChecklistTemplateSection.fromJson)
            .toList()
        : <ChecklistTemplateSection>[];

    return QrData(
      qrCodeString:        j['qr_code_string']?.toString() ?? '',
      vehicleId:           j['vehicle_id'] != null
                           ? int.tryParse(j['vehicle_id'].toString()) : null,
      vehicleNumber:       j['vehicle_number']?.toString() ?? '',
      vehicleType:         j['vehicle_type']?.toString(),
      trailerNumber:       j['trailer_number']?.toString(),
      vin:                 j['vin']?.toString(),
      plateNumber:         j['plate_number']?.toString(),
      fleetNumber:         j['fleet_number']?.toString(),
      companyName:         j['company_name']?.toString() ?? '',
      driverName:          j['driver_name']?.toString() ?? '',
      employeeId:          j['employee_id']?.toString() ?? '',
      driverPhone:         j['driver_phone']?.toString(),
      inspectionType:      j['inspection_type']?.toString(),
      pendingInspectionId: j['pending_inspection_id'] != null
                           ? int.tryParse(j['pending_inspection_id'].toString()) : null,
      pendingInspectionRef:j['pending_inspection_ref']?.toString(),
      templateId:          j['template_id'] != null
                           ? int.tryParse(j['template_id'].toString()) : null,
      postTripForced:      j['post_trip_forced'] == true || j['post_trip_forced'] == 1,
      checklistSections:   sections,
    );
  }
}

// ─── Checklist response (driver answers) ─────────────────────────────────────

class ChecklistResponse {
  final int?   templateItemId; // links to checklist_template_items.id
  final String sectionTitle;
  final String itemLabel;
  final String selectedOption; // display value e.g. 'Good', 'Available'
  final String response;       // db value e.g. 'good', 'available'
  final String? textValue;     // for text/number items

  const ChecklistResponse({
    this.templateItemId,
    required this.sectionTitle,
    required this.itemLabel,
    required this.selectedOption,
    required this.response,
    this.textValue,
  });

  Map<String, dynamic> toJson() => {
    'template_item_id': templateItemId,
    'section_id':       sectionTitle,
    'item_label':       itemLabel,
    'selected_option':  selectedOption,
    'response':         response,
    if (textValue != null) 'text_value': textValue,
  };
}

// ─── Defect report ────────────────────────────────────────────────────────────

class DefectReport {
  final String  category;
  final String  severity;
  final String  description;
  final int?    templateItemId;

  const DefectReport({
    required this.category,
    required this.severity,
    required this.description,
    this.templateItemId,
  });

  Map<String, dynamic> toJson() => {
    'category':         category,
    'severity':         severity,
    'description':      description,
    'template_item_id': templateItemId,
  };
}

// ─── GPS ─────────────────────────────────────────────────────────────────────

class GpsLocation {
  final double   latitude;
  final double   longitude;
  final String   address;
  final DateTime capturedAt;

  const GpsLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
    'latitude':    latitude,
    'longitude':   longitude,
    'address':     address,
    'captured_at': capturedAt.toIso8601String(),
  };

  factory GpsLocation.fromJson(Map<String, dynamic> j) => GpsLocation(
    latitude:   (j['latitude']  as num?)?.toDouble() ?? 0,
    longitude:  (j['longitude'] as num?)?.toDouble() ?? 0,
    address:    j['address']?.toString() ?? '',
    capturedAt: DateTime.tryParse(j['captured_at']?.toString() ?? '') ?? DateTime.now(),
  );
}

// ─── Inspection submission ────────────────────────────────────────────────────

class InspectionSubmission {
  final String                  qrCodeString;
  final String                  inspectionType;
  final int?                    pendingInspectionId;
  final int?                    templateId;
  final List<ChecklistResponse> responses;
  final List<DefectReport>      defects;
  final String?                 additionalNotes;
  final GpsLocation             gpsLocation;
  final DateTime                startedAt;
  // Vehicle display fields — carried from QrData for review/success screens
  final String                  vehicleNumber;
  final String?                 trailerNumber;

  const InspectionSubmission({
    required this.qrCodeString,
    required this.inspectionType,
    this.pendingInspectionId,
    this.templateId,
    required this.responses,
    required this.defects,
    this.additionalNotes,
    required this.gpsLocation,
    required this.startedAt,
    required this.vehicleNumber,
    this.trailerNumber,
  });

  // Computed stats used by review and success screens
  int get totalItems   => responses.length;
  int get passedItems  => responses.where((r) =>
      r.response == 'good' || r.response == 'available' ||
      r.response == 'yes'  || r.response == 'pass').length;
  int get defectCount  => defects.length;

  Map<String, dynamic> toJson() => {
    'qr_code_string':        qrCodeString,
    'inspection_type':       inspectionType,
    'pending_inspection_id': pendingInspectionId,
    'template_id':           templateId,
    'vehicle_number':        vehicleNumber,
    'trailer_number':        trailerNumber,
    'responses':             responses.map((r) => r.toJson()).toList(),
    'defects':               defects.map((d) => d.toJson()).toList(),
    'additional_notes':      additionalNotes ?? '',
    'gps_location':          gpsLocation.toJson(),
    'started_at':            startedAt.toIso8601String(),
  };
}

// ─── Inspection result (after submission) ────────────────────────────────────

class InspectionResult {
  final int       id;
  final String    inspectionId;
  final String    vehicleNumber;
  final String    inspectionType;
  final DateTime  assignDate;
  final DateTime? submittedAt;
  final String    status;
  final GpsLocation? gpsLocation; // available after submission

  const InspectionResult({
    required this.id,
    required this.inspectionId,
    required this.vehicleNumber,
    required this.inspectionType,
    required this.assignDate,
    this.submittedAt,
    required this.status,
    this.gpsLocation,
  });

  DateTime get displayDate => submittedAt ?? assignDate;

  factory InspectionResult.fromJson(Map<String, dynamic> j) => InspectionResult(
    id:             j['id'] != null ? int.tryParse(j['id'].toString()) ?? 0 : 0,
    inspectionId:   j['inspection_id']?.toString() ?? '',
    vehicleNumber:  j['vehicle_number']?.toString() ?? '',
    inspectionType: j['inspection_type']?.toString() ?? '',
    assignDate:     DateTime.tryParse(
                      j['created_at']?.toString() ??
                      j['date']?.toString() ?? '') ?? DateTime.now(),
    submittedAt:    j['submitted_at'] != null
                    ? DateTime.tryParse(j['submitted_at'].toString()) : null,
    status:         j['status']?.toString() ?? 'pending',
    gpsLocation:    j['gps_location'] != null
                    ? GpsLocation.fromJson(j['gps_location'] as Map<String, dynamic>)
                    : null,
  );

  /// Fills in any fields the server didn't echo back (some submit endpoints
  /// only return {id, inspection_id, status}) using values already known
  /// locally from the submission that was just sent.
  InspectionResult fillMissingFrom(InspectionSubmission submission) => InspectionResult(
    id:             id,
    inspectionId:   inspectionId,
    vehicleNumber:  vehicleNumber.isNotEmpty ? vehicleNumber : submission.vehicleNumber,
    inspectionType: inspectionType.isNotEmpty ? inspectionType : submission.inspectionType,
    assignDate:     assignDate,
    submittedAt:    submittedAt ?? submission.startedAt,
    status:         status,
    gpsLocation:    gpsLocation ?? submission.gpsLocation,
  );
}

// ─── Activity item (dashboard Recent Activity) ───────────────────────────────

class ActivityItem {
  final String   inspectionId;
  final String   vehicleNumber;
  final String   type;
  final String   status;
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
    status:        j['status']?.toString() ?? 'pending',
    date:          DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
  );
}
