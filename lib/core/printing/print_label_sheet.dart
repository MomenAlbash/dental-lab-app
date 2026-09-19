import 'dart:typed_data';

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/printing/label_printer_service.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Opens the printer picker and, once connected, sends [tsplBytes].
///
/// A device once connected stays connected on [LabelPrinterService] — calling
/// this again for a second label skips the picker and prints straight away.
Future<void> printLabel(
  BuildContext context, {
  required Uint8List tsplBytes,
}) async {
  final service = getIt<LabelPrinterService>();

  if (service.isConnected) {
    try {
      await service.printBytes(tsplBytes);
      if (context.mounted) {
        showToast(
          message: 'تم إرسال الملصق للطباعة',
          state: ToastState.success,
        );
      }
      return;
    } catch (e) {
      // Falls through to the picker: the printer may have gone out of range
      // since it last connected, and re-pairing is the recovery.
      if (context.mounted) {
        showToast(
          message: 'تعذّر الطباعة، أعد الاتصال بالطابعة',
          state: ToastState.warning,
        );
      }
    }
  }

  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PrinterPickerSheet(tsplBytes: tsplBytes),
  );
}

class _PrinterPickerSheet extends StatefulWidget {
  const _PrinterPickerSheet({required this.tsplBytes});

  final Uint8List tsplBytes;

  @override
  State<_PrinterPickerSheet> createState() => _PrinterPickerSheetState();
}

class _PrinterPickerSheetState extends State<_PrinterPickerSheet> {
  final _service = getIt<LabelPrinterService>();
  final List<ScanResult> _found = [];
  String? _error;
  bool _isScanning = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _error = null;
      _found.clear();
    });

    try {
      await for (final results in _service.scan()) {
        if (!mounted) return;
        setState(() {
          _found
            ..clear()
            ..addAll(results.where((r) => r.device.platformName.isNotEmpty));
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _connectAndPrint(BluetoothDevice device) async {
    setState(() => _isConnecting = true);
    try {
      await _service.connect(device);
      await _service.printBytes(widget.tsplBytes);
      if (mounted) {
        Navigator.of(context).pop();
        showToast(
          message: 'تم إرسال الملصق للطباعة',
          state: ToastState.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _error = 'تعذّر الاتصال أو الطباعة: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _service.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => GlassSheetSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'اختر طابعة الملصقات',
                      style: AppTextStyles.font18MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                  ),
                  if (_isScanning)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      tooltip: 'إعادة البحث',
                      onPressed: _startScan,
                      icon: const Icon(Icons.refresh),
                    ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  _error!,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.error,
                  ),
                ),
              ),
            Expanded(
              child: _found.isEmpty
                  ? Center(
                      child: Text(
                        _isScanning
                            ? 'جارٍ البحث عن أجهزة بلوتوث قريبة...'
                            : 'لم يتم العثور على أجهزة — تأكد أن الطابعة قيد التشغيل',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.font14RegularSecondary.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _found.length,
                      itemBuilder: (context, index) {
                        final result = _found[index];
                        return ListTile(
                          leading: Icon(
                            Icons.print_outlined,
                            color: glass.onGlassMuted,
                          ),
                          title: Text(result.device.platformName),
                          trailing: _isConnecting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                          onTap: _isConnecting
                              ? null
                              : () => _connectAndPrint(result.device),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
