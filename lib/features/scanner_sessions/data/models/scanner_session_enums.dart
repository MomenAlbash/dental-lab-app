/// Where a scanner session stands (`ScannerSessionStatus`).
///
/// [badgeVariant] is a design-token *name*, resolved through
/// `badgeVariantColor` — a stored colour would ignore the lab's brand and
/// break in dark mode (MOBILE-SPEC §17.8).
enum ScannerSessionStatus {
  requested(1, 'مطلوبة', 'warning'),
  scheduled(2, 'مجدولة', 'primary'),
  awaitingDoctorCompletion(3, 'بانتظار الطبيب', 'warning'),
  completed(4, 'منتهية', 'success'),
  cancelled(5, 'ملغاة', 'secondary'),
  noShow(6, 'لم يحضر', 'destructive');

  const ScannerSessionStatus(this.value, this.label, this.badgeVariant);

  final int value;
  final String label;
  final String badgeVariant;

  /// Still expected to happen. The dispatcher's queue is exactly this set.
  bool get isOpen =>
      this == ScannerSessionStatus.requested ||
      this == ScannerSessionStatus.scheduled ||
      this == ScannerSessionStatus.awaitingDoctorCompletion;

  static ScannerSessionStatus? fromValue(int? value) {
    for (final status in ScannerSessionStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

/// Whether the assigned representative has answered (`RepresentativeResponse`).
///
/// A refusal is not a failure state for the session — it is the signal to
/// assign someone else, which is why it reads as its own thing rather than as
/// an error.
enum RepresentativeResponse {
  pending(1, 'بانتظار الرد', 'warning'),
  accepted(2, 'قبل', 'success'),
  declined(3, 'اعتذر', 'destructive');

  const RepresentativeResponse(this.value, this.label, this.badgeVariant);

  final int value;
  final String label;
  final String badgeVariant;

  /// The dispatcher has to act: nobody is coming unless someone else is sent.
  bool get needsReassignment => this == RepresentativeResponse.declined;

  static RepresentativeResponse? fromValue(int? value) {
    for (final response in RepresentativeResponse.values) {
      if (response.value == value) return response;
    }
    return null;
  }
}

/// Control's verdict on the scan (`ScannerReviewStatus`).
enum ScannerReviewStatus {
  pendingReview(1, 'بانتظار المراجعة', 'warning'),
  approved(2, 'مقبول', 'success'),
  redoRequested(3, 'مطلوب إعادة', 'destructive');

  const ScannerReviewStatus(this.value, this.label, this.badgeVariant);

  final int value;
  final String label;
  final String badgeVariant;

  static ScannerReviewStatus? fromValue(int? value) {
    for (final status in ScannerReviewStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}
