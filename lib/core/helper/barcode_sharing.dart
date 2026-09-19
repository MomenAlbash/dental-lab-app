import 'dart:io';
import 'dart:ui' as ui;

import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Shares a barcode as a picture rather than as text.
///
/// Copying the code's text hands over a number, which is all the code encodes
/// — correct, but useless to somebody who wanted to send the sticker itself.
/// This renders the same payload to a PNG and hands it to the system share
/// sheet, so a case's code can go into a chat, an email or the gallery.
Future<void> shareBarcodeImage({
  required String payload,
  required String title,
  String? fileName,
}) async {
  final bytes = await _renderQrPng(payload);
  if (bytes == null) {
    showToast(message: 'تعذّر إنشاء صورة الباركود', state: ToastState.error);
    return;
  }

  // Written to a real file rather than shared from memory: several targets
  // (and older Android share sheets) refuse an in-memory image.
  final directory = await getTemporaryDirectory();
  final safeName = (fileName ?? payload).replaceAll(RegExp(r'[^\w\-]'), '_');
  final file = await File(
    '${directory.path}/barcode_$safeName.png',
  ).writeAsBytes(bytes);

  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], text: title),
  );
}

/// The QR as PNG bytes, drawn at a size a phone camera can actually read off
/// another screen — a small code shared into a chat is a code nobody can scan.
///
/// Painted onto an explicit white canvas with a quiet zone around it.
/// `QrPainter.toImageData` draws only the modules and leaves the rest
/// transparent, and a transparent PNG lands in a chat as a solid black square
/// — which is a code no scanner will ever read.
/// Exposed for a rendering check in tests — the failure this guards against
/// (a transparent PNG that reads as a black square) is invisible to a unit
/// test that only asserts "some bytes came back".
@visibleForTesting
Future<Uint8List?> debugRenderQrPng(String payload) => _renderQrPng(payload);

Future<Uint8List?> _renderQrPng(String payload) async {
  const size = 720.0;
  const quietZone = 48.0;

  final painter = QrPainter(
    data: payload,
    version: QrVersions.auto,
    gapless: true,
    // Black on white regardless of the app's theme: a scanner needs the
    // contrast, and a shared picture has no theme to inherit.
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      
      color: ui.Color(0xFF000000),
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: ui.Color(0xFF000000),
    ),
  );

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, size, size));

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, size, size),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );

  canvas.save();
  canvas.translate(quietZone, quietZone);
  painter.paint(
    canvas,
    const ui.Size(size - quietZone * 2, size - quietZone * 2),
  );
  canvas.restore();

  final image = await recorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  return data?.buffer.asUint8List();
}
