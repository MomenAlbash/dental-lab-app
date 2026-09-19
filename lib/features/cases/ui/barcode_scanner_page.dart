import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/logic/barcode_scan/barcode_scan_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/barcode_scan/barcode_scan_state.dart';
import 'package:dental_lab_app/features/cases/ui/scan_task_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Reads the barcode printed on a case ticket or on a restoration, and opens
/// what it names.
///
/// This is the shop-floor path into the app: a technician holding a piece
/// should not have to know its case number, search for it, and pick it out of
/// a list — they point the camera at the sticker and land on the work.
class BarcodeScannerPage extends StatelessWidget {
  const BarcodeScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BarcodeScanCubit>(),
      child: const _BarcodeScannerView(),
    );
  }
}

class _BarcodeScannerView extends StatefulWidget {
  const _BarcodeScannerView();

  @override
  State<_BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<_BarcodeScannerView> {
  /// Owned by the state, never rebuilt in `build` — a controller created there
  /// would restart the camera on every frame.
  final MobileScannerController _controller = MobileScannerController(
    // One format-agnostic read: the lab may print QR on the ticket and a 1D
    // code on the piece, and the app has no business caring which.
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere(
          (value) => value != null && value.trim().isNotEmpty,
          orElse: () => null,
        );
    if (code == null) return;

    context.read<BarcodeScanCubit>().resolve(code);
  }

  void _openCase(String caseId) {
    // Replaces the scanner rather than stacking on it: the camera has done its
    // job, and coming back from the case to a live viewfinder is not what
    // "back" means here.
    context.pushReplacement(Routes.caseDetailScreen, extra: caseId);
  }

  /// A scanned piece opens the task screen, not the case sheet.
  ///
  /// Scanning a unit's own label is the shop-floor gesture: whoever did it is
  /// holding that piece and wants to know whether it is theirs to move on.
  /// The full case sheet is a manager's screen — and largely redacted for a
  /// non-admin employee anyway — so it stays one tap away instead of being
  /// the destination.
  void _openTask(CaseDetailModel caseDetail, String restorationId) {
    context.pushReplacement(
      Routes.scanTaskScreen,
      extra: ScanTaskArgs(caseDetail: caseDetail, restorationId: restorationId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'مسح الباركود',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
        actions: [
          IconButton(
            tooltip: 'الإضاءة',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
          IconButton(
            tooltip: 'تبديل الكاميرا',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: BlocConsumer<BarcodeScanCubit, BarcodeScanState>(
        listener: (context, state) {
          switch (state) {
            case BarcodeScanCaseFound(:final caseDetail):
              _openCase(caseDetail.id);
            case BarcodeScanRestorationFound(
              :final caseDetail,
              :final restorationId,
            ):
              _openTask(caseDetail, restorationId);
            default:
              break;
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Positioned.fill(
                child: MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  // Shown instead of a black rectangle when the camera is
                  // refused: a viewfinder that never turns on reads as a bug.
                  errorBuilder: (context, error) =>
                      _CameraProblem(error: error),
                ),
              ),
              const Positioned.fill(child: _ScanFrame()),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _ScanStatus(state: state),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The cut-out the user aims with. A full-screen camera with no frame gives no
/// clue how close to hold the sticker.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.72,
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(AppRadius.glassLg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the scanner is doing, said in the one place the user is looking.
class _ScanStatus extends StatelessWidget {
  const _ScanStatus({required this.state});

  final BarcodeScanState state;

  @override
  Widget build(BuildContext context) {
    final (String message, bool isProblem) = switch (state) {
      BarcodeScanIdle() => (
        'وجّه الكاميرا نحو باركود الحالة أو التعويض',
        false,
      ),
      BarcodeScanResolving() => ('جارٍ البحث...', false),
      BarcodeScanNotFound(:final code) => (
        'لا توجد حالة أو تعويض بهذا الباركود ($code)',
        true,
      ),
      BarcodeScanCaseFound() => ('تم العثور على الحالة — جارٍ فتحها', false),
      BarcodeScanRestorationFound(:final restorationNumber) => (
        'تم العثور على التعويض ${restorationNumber ?? ''} — جارٍ فتح المهمة',
        false,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        children: [
          if (state is BarcodeScanResolving)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              isProblem ? Icons.error_outline : Icons.qr_code_scanner,
              color: Colors.white,
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.font14MediumText.copyWith(
                color: Colors.white,
              ),
            ),
          ),
          if (state is BarcodeScanNotFound)
            TextButton(
              onPressed: () => context.read<BarcodeScanCubit>().reset(),
              child: const Text('حاول مجدداً'),
            ),
        ],
      ),
    );
  }
}

/// Said plainly when the camera itself is the problem — most often a refused
/// permission, which no amount of pointing at a sticker will fix.
class _CameraProblem extends StatelessWidget {
  const _CameraProblem({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'الكاميرا مرفوضة — فعّلها من إعدادات التطبيق لتتمكن من المسح',
      MobileScannerErrorCode.unsupported => 'هذا الجهاز لا يدعم مسح الباركود',
      _ => 'تعذّر تشغيل الكاميرا',
    };

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.font14MediumText.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'يمكنك أيضاً البحث عن الحالة برقمها من شاشة الحالات',
                textAlign: TextAlign.center,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
