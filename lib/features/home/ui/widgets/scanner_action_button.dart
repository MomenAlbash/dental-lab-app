import 'package:dental_lab_app/core/helper/feature_hints.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The home screen's barcode scanner button. With [introduce] set, the first
/// time it appears it points itself out in a small bubble — the icon alone
/// does not say that scanning a ticket opens the work directly.
class ScannerActionButton extends StatefulWidget {
  const ScannerActionButton({super.key, this.introduce = false});

  /// Whether this user should get the one-time bubble (the caller leaves
  /// admins out). It still shows only once per device.
  final bool introduce;

  @override
  State<ScannerActionButton> createState() => _ScannerActionButtonState();
}

class _ScannerActionButtonState extends State<ScannerActionButton> {
  final _link = LayerLink();
  final _hint = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    if (widget.introduce && !FeatureHint.barcodeScanner.isSeen) {
      // After the first frame: the button must be laid out before the bubble
      // can anchor to it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _hint.show();
      });
    }
  }

  void _dismiss() {
    if (!_hint.isShowing) return;
    _hint.hide();
    FeatureHint.barcodeScanner.markSeen();
  }

  void _openScanner() {
    _dismiss();
    context.push(Routes.barcodeScannerScreen);
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _hint,
      overlayChildBuilder: (_) =>
          _HintBubble(link: _link, onDismiss: _dismiss, onTry: _openScanner),
      child: CompositedTransformTarget(
        link: _link,
        child: IconButton(
          tooltip: 'مسح باركود حالة أو تعويض',
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: _openScanner,
        ),
      ),
    );
  }
}

class _HintBubble extends StatelessWidget {
  const _HintBubble({
    required this.link,
    required this.onDismiss,
    required this.onTry,
  });

  final LayerLink link;
  final VoidCallback onDismiss;
  final VoidCallback onTry;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;
    // App-bar actions sit on the trailing edge; the bubble grows from that
    // edge inwards so it never runs off the screen.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final edge = isRtl ? Alignment.bottomLeft : Alignment.bottomRight;
    final width = (MediaQuery.sizeOf(context).width - 2 * AppSpacing.lg).clamp(
      0.0,
      300.0,
    );

    return Stack(
      children: [
        // Any tap outside the bubble dismisses it.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.25)),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          targetAnchor: edge,
          followerAnchor: isRtl ? Alignment.topLeft : Alignment.topRight,
          offset: const Offset(0, AppSpacing.sm),
          child: UnconstrainedBox(
            child: SizedBox(
              width: width,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                elevation: 6,
                borderRadius: BorderRadius.circular(AppRadius.glass),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.qr_code_scanner, color: accent),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'لاقط الباركود',
                              style: AppTextStyles.font16MediumText.copyWith(
                                color: glass.onGlass,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'امسح باركود تيكت الحالة أو التعويض لتفتحه مباشرة '
                        'بدون بحث.',
                        style: AppTextStyles.font14RegularSecondary.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: onDismiss,
                            child: const Text('فهمت'),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          FilledButton(
                            onPressed: onTry,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                            child: const Text('جرّبه'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
