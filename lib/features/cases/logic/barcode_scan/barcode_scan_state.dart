import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';

sealed class BarcodeScanState {
  const BarcodeScanState();
}

/// The camera is looking, nothing resolved yet.
class BarcodeScanIdle extends BarcodeScanState {
  const BarcodeScanIdle();
}

class BarcodeScanResolving extends BarcodeScanState {
  const BarcodeScanResolving(this.code);
  final String code;
}

class BarcodeScanCaseFound extends BarcodeScanState {
  const BarcodeScanCaseFound(this.caseDetail);
  final CaseDetailModel caseDetail;
}

/// A restoration barcode: the case it belongs to, and which line was scanned.
class BarcodeScanRestorationFound extends BarcodeScanState {
  const BarcodeScanRestorationFound({
    required this.caseDetail,
    required this.restorationId,
    required this.restorationNumber,
  });

  final CaseDetailModel caseDetail;
  final String restorationId;
  final String? restorationNumber;
}

/// The code was read but names nothing the lab has.
///
/// Carries the code itself: an unreadable sticker and a code from another
/// lab's ticket look the same on screen otherwise.
class BarcodeScanNotFound extends BarcodeScanState {
  const BarcodeScanNotFound({required this.code});
  final String code;
}
