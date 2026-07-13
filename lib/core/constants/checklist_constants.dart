class ChecklistSection {
  final String id;
  final String title;
  final List<ChecklistItem> items;
  final String applicableTo; // 'both', 'pre', 'post'

  const ChecklistSection({
    required this.id,
    required this.title,
    required this.items,
    this.applicableTo = 'both',
  });
}

class ChecklistItem {
  final String id;
  final String label;
  final List<String> options; // e.g. ['Good','Defective'] or ['Available','Not Available'] or ['Yes','No']

  const ChecklistItem({
    required this.id,
    required this.label,
    required this.options,
  });
}

class ChecklistConstants {
  ChecklistConstants._();

  static const List<String> goodDefective      = ['Good', 'Defective'];
  static const List<String> availableOptions   = ['Available', 'Not Available'];
  static const List<String> yesNoOptions       = ['Yes', 'No'];

  static List<ChecklistSection> preTripSections() => [
    const ChecklistSection(
      id: 's1', title: 'Vehicle Exterior', applicableTo: 'both',
      items: [
        ChecklistItem(id: 's1_headlights',    label: 'Headlights',    options: goodDefective),
        ChecklistItem(id: 's1_brakelights',   label: 'Brake Lights',  options: goodDefective),
        ChecklistItem(id: 's1_turnsignals',   label: 'Turn Signals',  options: goodDefective),
        ChecklistItem(id: 's1_reflectors',    label: 'Reflectors',    options: goodDefective),
        ChecklistItem(id: 's1_mirrors',       label: 'Mirrors',       options: goodDefective),
        ChecklistItem(id: 's1_windshield',    label: 'Windshield',    options: goodDefective),
        ChecklistItem(id: 's1_wipers',        label: 'Wipers',        options: goodDefective),
        ChecklistItem(id: 's1_horn',          label: 'Horn',          options: goodDefective),
      ],
    ),
    const ChecklistSection(
      id: 's2', title: 'Tires & Wheels', applicableTo: 'both',
      items: [
        ChecklistItem(id: 's2_pressure',   label: 'Tire Pressure',  options: goodDefective),
        ChecklistItem(id: 's2_condition',  label: 'Tire Condition', options: goodDefective),
        ChecklistItem(id: 's2_wheelnuts',  label: 'Wheel Nuts',     options: goodDefective),
        ChecklistItem(id: 's2_rims',       label: 'Rims',           options: goodDefective),
        ChecklistItem(id: 's2_suspension', label: 'Suspension',     options: goodDefective),
      ],
    ),
    const ChecklistSection(
      id: 's3', title: 'Engine Compartment', applicableTo: 'both',
      items: [
        ChecklistItem(id: 's3_oil',          label: 'Oil Level',      options: goodDefective),
        ChecklistItem(id: 's3_coolant',      label: 'Coolant Level',  options: goodDefective),
        ChecklistItem(id: 's3_belts',        label: 'Belts',          options: goodDefective),
        ChecklistItem(id: 's3_battery',      label: 'Battery',        options: goodDefective),
        ChecklistItem(id: 's3_compressor',   label: 'Air Compressor', options: goodDefective),
      ],
    ),
    const ChecklistSection(
      id: 's4', title: 'Brakes', applicableTo: 'both',
      items: [
        ChecklistItem(id: 's4_parking',   label: 'Parking Brake',    options: goodDefective),
        ChecklistItem(id: 's4_service',   label: 'Service Brake',    options: goodDefective),
        ChecklistItem(id: 's4_airbrake',  label: 'Air Brake System', options: goodDefective),
        ChecklistItem(id: 's4_hoses',     label: 'Brake Hoses',      options: goodDefective),
      ],
    ),
    const ChecklistSection(
      id: 's5', title: 'Safety Equipment', applicableTo: 'both',
      items: [
        ChecklistItem(id: 's5_extinguisher', label: 'Fire Extinguisher',   options: availableOptions),
        ChecklistItem(id: 's5_triangles',    label: 'Emergency Triangles', options: availableOptions),
        ChecklistItem(id: 's5_firstaid',     label: 'First Aid Kit',       options: availableOptions),
        ChecklistItem(id: 's5_seatbelt',     label: 'Seat Belt',           options: availableOptions),
      ],
    ),
    // Section 6: Additional Notes — items is empty, which triggers the notes
    // text area in ChecklistScreen via the _isNotesSection getter.
    // Character limit: 1000. Optional — driver may skip.
    const ChecklistSection(
      id: 's6_notes', title: 'Additional Notes', applicableTo: 'both',
      items: [], // empty = notes text area, no checkboxes
    ),
  ];

  static List<ChecklistSection> postTripSections() => [
    ...preTripSections().where((s) => s.id != 's6_notes'),
    const ChecklistSection(
      id: 's6', title: 'Vehicle Damage', applicableTo: 'post',
      items: [
        ChecklistItem(id: 's6_bodydamage',  label: 'Body Damage',       options: yesNoOptions),
        ChecklistItem(id: 's6_tiredamage',  label: 'Tire Damage',       options: yesNoOptions),
        ChecklistItem(id: 's6_mechanical',  label: 'Mechanical Issues', options: yesNoOptions),
        ChecklistItem(id: 's6_accident',    label: 'Accident Report',   options: yesNoOptions),
      ],
    ),
    // Section 7: Additional Notes for Post-Trip
    const ChecklistSection(
      id: 's7_notes', title: 'Additional Notes', applicableTo: 'post',
      items: [], // empty = notes text area
    ),
  ];

  static const List<String> defectCategories = [
    'Body Damage',
    'Tire Damage',
    'Mechanical Issues',
    'Accident Report',
  ];

  static const List<String> severityLevels = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];
}
