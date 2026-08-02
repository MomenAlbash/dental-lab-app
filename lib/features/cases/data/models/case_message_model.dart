import 'package:dental_lab_app/features/cases/data/models/case_message_attachment_type.dart';

/*
{
  "id": "...",
  "caseId": "...",
  "senderId": "...",
  "senderName": "د. خالد",
  "message": "الحالة جاهزة للتسليم",
  "sentAt": "2026-08-01T10:12:33.000Z",
  "replyToMessageId": null,
  "attachmentPath": "/uploads/messages/xyz.mp3",
  "attachmentFileName": "voice-note.mp3",
  "attachmentType": 3
}
 */

/// A message on a case's conversation (`ClinicCaseMessageDto`).
class CaseMessageModel {
  final String id;
  final String caseId;
  final String senderId;
  final String? senderName;
  final String? message;
  final DateTime? sentAt;
  final String? replyToMessageId;
  final String? attachmentPath;
  final String? attachmentFileName;
  final CaseMessageAttachmentType? attachmentType;

  CaseMessageModel({
    required this.id,
    required this.caseId,
    required this.senderId,
    this.senderName,
    this.message,
    this.sentAt,
    this.replyToMessageId,
    this.attachmentPath,
    this.attachmentFileName,
    this.attachmentType,
  });

  factory CaseMessageModel.fromJson(Map<String, dynamic> json) {
    return CaseMessageModel(
      id: json['id'] as String,
      caseId: json['caseId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String?,
      message: json['message'] as String?,
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'] as String)
          : null,
      replyToMessageId: json['replyToMessageId'] as String?,
      attachmentPath: json['attachmentPath'] as String?,
      attachmentFileName: json['attachmentFileName'] as String?,
      attachmentType: CaseMessageAttachmentType.fromApi(
        json['attachmentType'] as int?,
      ),
    );
  }
}
