/// `RegisterDeviceTokenRequest.platform` — `1 = Android, 2 = iOS, 3 = Web`.
enum DevicePlatform {
  android(1),
  ios(2),
  web(3);

  const DevicePlatform(this.value);
  final int value;
}

/// `ClinicNotificationDto.type` — what [NotificationModel.relatedEntityId]
/// points at. Confirmed against a real payload (see [NotificationModel]).
enum NotificationType {
  caseType(1),
  appointment(2),
  payment(3),
  order(4),
  attendance(5),
  system(6);

  const NotificationType(this.value);
  final int value;

  static NotificationType? fromValue(int? value) {
    for (final type in NotificationType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// An in-app notification (`ClinicNotificationDto`).
///
/// Field names confirmed against a real `GET /Notifications` payload:
/// ```json
/// {
///   "id": "ef832565-fb0a-457d-b80e-b255e49a1ad4",
///   "type": 1,
///   "title": "حالة تجاوزت الوقت المتوقع",
///   "body": "الحالة C2608253934 تجاوزت الوقت المتوقع بـ 0 ساعة.",
///   "relatedEntityType": "Case",
///   "relatedEntityId": "302b6e6e-dce1-419d-9575-75a69ea78ada",
///   "isRead": false,
///   "createdAt": "2026-08-25T12:10:31.1104701"
/// }
/// ```
class NotificationModel {
  final String id;
  final NotificationType? type;
  final String? title;
  final String? message;

  /// What [type] refers to — a case id when [type] is
  /// [NotificationType.caseType], and so on. Null for a type this app has no
  /// detail screen for yet ([NotificationType.system], for instance), even
  /// when the server sends one.
  final String? relatedEntityId;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    this.type,
    this.title,
    this.message,
    this.relatedEntityId,
    this.isRead = false,
    this.createdAt,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      message: message,
      relatedEntityId: relatedEntityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      type: NotificationType.fromValue(json['type'] as int?),
      title: json['title'] as String?,
      message: json['body'] as String?,
      relatedEntityId: json['relatedEntityId'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
