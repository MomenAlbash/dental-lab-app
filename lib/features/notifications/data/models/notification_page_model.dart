import 'package:dental_lab_app/features/notifications/data/models/notification_model.dart';

/// One page of `GET /Notifications/paged`.
///
/// The endpoint declares no response schema, so this is built from two things
/// that *are* known rather than from guesswork: [NotificationModel] is the
/// shape the working `GET /Notifications` already returns, and the envelope is
/// the one the backend documents on its other paged endpoint
/// (`EmployeeActivity/timeline` — `items/page/pageSize/totalCount/
/// totalPages`). If the server turns out to name them differently, every field
/// degrades to its default and the list simply shows one page rather than
/// throwing.
class NotificationPageModel {
  const NotificationPageModel({
    this.items = const [],
    this.page = 1,
    this.pageSize = 0,
    this.totalCount = 0,
    this.totalPages = 0,
  });

  final List<NotificationModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory NotificationPageModel.fromJson(Map<String, dynamic> json) {
    return NotificationPageModel(
      items: [
        for (final entry in json['items'] as List<dynamic>? ?? const [])
          if (entry is Map<String, dynamic>) NotificationModel.fromJson(entry),
      ],
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  /// The shape a bare list would arrive in, if the endpoint answers with one
  /// rather than an envelope.
  ///
  /// Not defensive padding: a list and an envelope are both plausible readings
  /// of an undocumented `200 OK`, and the difference between them is one page
  /// versus an empty screen.
  factory NotificationPageModel.fromList(List<dynamic> data) {
    final items = [
      for (final entry in data)
        if (entry is Map<String, dynamic>) NotificationModel.fromJson(entry),
    ];

    return NotificationPageModel(
      items: items,
      pageSize: items.length,
      totalCount: items.length,
      totalPages: 1,
    );
  }
}

/// Who a broadcast goes to (`BroadcastAudience`).
enum BroadcastAudience {
  employees(1, 'كل الموظفين'),
  doctors(2, 'كل الأطباء'),
  specificUsers(3, 'مستخدمون محدّدون');

  const BroadcastAudience(this.value, this.label);

  final int value;
  final String label;

  static BroadcastAudience? fromValue(int? value) {
    for (final audience in values) {
      if (audience.value == value) return audience;
    }
    return null;
  }
}

/// `POST /Notifications/broadcast` (`ClinicBroadcastNotificationRequest`).
///
/// A push to many people at once, so it is the one write in this app with no
/// undo — sent is sent. [userIds] applies only to
/// [BroadcastAudience.specificUsers]; it is dropped for the two blanket
/// audiences so a half-finished selection cannot silently narrow a message
/// meant for everybody.
class BroadcastNotificationRequestModel {
  const BroadcastNotificationRequestModel({
    required this.audience,
    required this.title,
    required this.body,
    this.userIds = const [],
  });

  final BroadcastAudience audience;
  final String title;
  final String body;
  final List<String> userIds;

  /// Whether this request is actually sendable.
  ///
  /// Checked here rather than only in the form, because "specific users" with
  /// nobody chosen would reach every reading of that audience the server
  /// might take — including none at all, which looks like a delivery failure.
  bool get isValid {
    if (title.trim().isEmpty || body.trim().isEmpty) return false;
    if (audience == BroadcastAudience.specificUsers && userIds.isEmpty) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'audience': audience.value,
    'title': title,
    'body': body,
    'userIds': audience == BroadcastAudience.specificUsers
        ? userIds
        : const <String>[],
  };
}
