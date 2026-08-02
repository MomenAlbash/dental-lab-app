/// Type of attachment on a case message (`CaseMessageAttachmentType`), set by
/// the server based on the uploaded file — never chosen by the client.
enum CaseMessageAttachmentType {
  image(1),
  video(2),
  audio(3),
  file(4);

  const CaseMessageAttachmentType(this.apiValue);

  final int apiValue;

  static CaseMessageAttachmentType? fromApi(int? value) => switch (value) {
    1 => CaseMessageAttachmentType.image,
    2 => CaseMessageAttachmentType.video,
    3 => CaseMessageAttachmentType.audio,
    4 => CaseMessageAttachmentType.file,
    _ => null,
  };
}
