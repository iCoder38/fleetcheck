class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type; // 'new_assignment' | 'reminder' | 'system_update' | ...
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
        id: j['id'] != null ? int.tryParse(j['id'].toString()) ?? 0 : 0,
        title: j['title']?.toString() ?? '',
        message: j['message']?.toString() ?? '',
        type: j['type']?.toString() ?? '',
        isRead: j['is_read'] == true || j['is_read'] == 1,
        createdAt:
            DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
        referenceId: j['reference_id']?.toString(),
      );
}
