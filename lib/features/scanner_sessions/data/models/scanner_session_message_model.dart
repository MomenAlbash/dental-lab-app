import 'package:dental_lab_app/core/helper/api_time_helper.dart';

/// One message on a scanner session (`ClinicScannerSessionMessageDto`).
///
/// The thread between the lab and the doctor about one appointment — "the
/// scanner is free an hour earlier", "bring the old bridge". Kept on the
/// session rather than on a case because at booking time there is usually no
/// case yet; the case is what the session produces.
class ScannerSessionMessageModel {
  const ScannerSessionMessageModel({
    required this.id,
    required this.scannerSessionId,
    required this.senderId,
    this.senderName,
    this.isMine = false,
    this.isFromDoctor = false,
    this.message,
    this.sentAt,
    this.editedAt,
    this.readAt,
  });

  final String id;
  final String scannerSessionId;
  final String senderId;
  final String? senderName;

  /// Whether this session's viewer wrote it — the server decides, because the
  /// client cannot: a lab has many users, and "my" messages are the ones sent
  /// by *this login*, not by anyone on the lab's side.
  final bool isMine;

  /// Which side of the conversation it came from. Separate from [isMine]: a
  /// colleague's message is not mine but is still the lab's, and drawing it on
  /// the doctor's side would misattribute what the lab itself promised.
  final bool isFromDoctor;

  final String? message;
  final DateTime? sentAt;
  final DateTime? editedAt;

  /// When the other side read it. Null means unread — the distinction the
  /// read receipt is for, so it is never defaulted to a date.
  final DateTime? readAt;

  bool get isRead => readAt != null;
  bool get wasEdited => editedAt != null;

  String get displaySender {
    final name = senderName?.trim();
    return (name == null || name.isEmpty) ? '—' : name;
  }

  factory ScannerSessionMessageModel.fromJson(Map<String, dynamic> json) {
    return ScannerSessionMessageModel(
      id: json['id'] as String? ?? '',
      scannerSessionId: json['scannerSessionId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String?,
      isMine: json['isMine'] as bool? ?? false,
      isFromDoctor: json['isFromDoctor'] as bool? ?? false,
      message: json['message'] as String?,
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? ''),
      editedAt: DateTime.tryParse(json['editedAt'] as String? ?? ''),
      readAt: DateTime.tryParse(json['readAt'] as String? ?? ''),
    );
  }

  /// When it was sent, plus a marker when it was edited afterwards — an edited
  /// message reading as the original is how a thread stops being a record of
  /// what was actually agreed.
  String get timeLabel {
    final stamp = ApiTime.displayDateTime(sentAt);
    return wasEdited ? '$stamp · مُعدَّل' : stamp;
  }
}
