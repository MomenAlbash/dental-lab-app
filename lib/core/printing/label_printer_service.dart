import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dental_lab_app/core/permissions/bluetooth_permission.dart';
import 'package:dental_lab_app/core/printing/tspl_bitmap_text.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Talks to a Bluetooth Low Energy label printer (Xprinter and the many
/// clones built on the same chipset) over whatever writable characteristic it
/// exposes.
///
/// **Why BLE instead of the classic Bluetooth SPP most label-printer guides
/// assume**: classic sockets are unusable on iOS without an MFi-certified
/// accessory, and this app needs both platforms. These printers also answer
/// to BLE — the trade-off is that there is no standard "printer" BLE
/// profile, so the writable characteristic is discovered rather than
/// addressed by a fixed UUID. That makes this opportunistic: it works with
/// printers that expose exactly one writable characteristic (the common
/// case for this class of device), and may need adjusting for a unit that
/// exposes several genuine services.
///
/// **The label layout in [buildCaseLabel] is TSPL** (the command language
/// these printers speak out of the box) **and is unverified against real
/// hardware** — coordinates assume 203dpi (8 dots/mm), which is the class's
/// near-universal density, but must be checked against a printed label and
/// adjusted if it doesn't fit.
class LabelPrinterService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;

  bool get isConnected => _device != null && _writeCharacteristic != null;

  /// Scans for nearby Bluetooth devices for the user to pick from.
  ///
  /// Every advertising device is surfaced rather than filtered to "printer-
  /// looking" names: the lab's unit may not carry "printer" anywhere in its
  /// name, and a wrong guess here hides the very device the user needs.
  Stream<List<ScanResult>> scan({
    Duration timeout = const Duration(seconds: 8),
  }) async* {
    if (!await ensureBluetoothPermission()) {
      throw StateError('صلاحية البلوتوث مرفوضة');
    }
    if (!await FlutterBluePlus.isSupported) {
      throw StateError('الجهاز لا يدعم البلوتوث');
    }

    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: (sink) => sink.addError(
            StateError('فعّل البلوتوث من إعدادات الجهاز أولاً'),
          ),
        )
        .first;

    await FlutterBluePlus.startScan(timeout: timeout);
    yield* FlutterBluePlus.scanResults;
  }

  Future<void> stopScan() => FlutterBluePlus.stopScan();

  /// Connects to [device] and finds a characteristic to write to.
  ///
  /// Picks the first one advertising `write` or `writeWithoutResponse` —
  /// see the class doc for why that is a bet rather than a certainty.
  Future<void> connect(BluetoothDevice device) async {
    await disconnect();

    await device.connect(timeout: const Duration(seconds: 10));
    final services = await device.discoverServices();

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse) {
          _device = device;
          _writeCharacteristic = characteristic;
          return;
        }
      }
    }

    await device.disconnect();
    throw StateError('لم يتم العثور على منفذ كتابة على هذه الطابعة');
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;
    _writeCharacteristic = null;
  }

  /// Sends [bytes] in MTU-sized chunks — most of these BLE stacks silently
  /// drop anything past ~20 bytes on a single `writeWithoutResponse` call,
  /// which is what made a short test label print but a real one cut off
  /// halfway through the barcode.
  Future<void> _write(List<int> bytes) async {
    final characteristic = _writeCharacteristic;
    if (characteristic == null) {
      throw StateError('لا يوجد اتصال بالطابعة');
    }

    const chunkSize = 180;
    final withoutResponse =
        !characteristic.properties.write &&
        characteristic.properties.writeWithoutResponse;

    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize < bytes.length)
          ? offset + chunkSize
          : bytes.length;
      await characteristic.write(
        bytes.sublist(offset, end),
        withoutResponse: withoutResponse,
      );
      // A short pause between chunks — writing back-to-back with no gap is
      // what causes the printer's own buffer to drop bytes on cheap modules.
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  Future<void> printBytes(Uint8List tsplBytes) async {
    log('Printing label (${tsplBytes.length} bytes)');
    await _write(tsplBytes);
  }

  /// A 50×70mm case label: the case number large, the QR payload, and the
  /// patient/doctor underneath. Sized for the label stock in hand — pass a
  /// different [widthMm]/[heightMm] for another roll.
  ///
  /// **Coordinates are in dots at 8 dots/mm (203dpi)** — TSPL's `SIZE`/`GAP`
  /// commands take millimetres, but `TEXT`/`QRCODE`/`BITMAP` positions do
  /// not, so they are computed here rather than left in mm.
  ///
  /// Patient/doctor names go through [TsplBitmapText] when they contain
  /// anything outside ASCII — the printer's built-in font has no Arabic
  /// glyphs (confirmed on real hardware: it prints unrelated symbols
  /// instead). The case number stays on the fast native `TEXT` path since
  /// case numbers are ASCII in practice.
  static Future<Uint8List> buildCaseLabel({
    required String caseNumber,
    required String qrPayload,
    String? patientName,
    String? doctorName,
    double widthMm = 50,
    double heightMm = 70,
    // TSPL's own "cell size" — dots per QR module. Pushed to the largest
    // value that still fits the worst-case module count (below) inside a
    // 50mm label with a safe quiet zone either side; going higher would run
    // the code off the edge on a longer payload.
    int qrCellSize = 11,
  }) async {
    const dotsPerMm = 8;
    final widthDots = (widthMm * dotsPerMm).round();
    final heightDots = (heightMm * dotsPerMm).round();
    const margin = 20;
    final boxWidth = (widthDots - margin * 2).clamp(1, widthDots);

    // Worst-case QR version for a short case number/uuid-ish payload is
    // ~33 modules (ECC L); sized generously rather than exactly, so the QR
    // is centred — and the text below it placed — against the largest size
    // it could actually come out at, not the smallest.
    final qrSizeDots = qrCellSize * 33;
    final qrX = ((widthDots - qrSizeDots) / 2).round().clamp(0, widthDots);
    const gap = 20;

    final caseNumberPiece = await _prepareLabelText(
      caseNumber,
      boxWidth: boxWidth,
      fontSize: 22,
      centered: true,
    );
    final patientPiece = (patientName != null && patientName.isNotEmpty)
        ? await _prepareLabelText(patientName, boxWidth: boxWidth, fontSize: 16)
        : null;
    final doctorPiece = (doctorName != null && doctorName.isNotEmpty)
        ? await _prepareLabelText(doctorName, boxWidth: boxWidth, fontSize: 16)
        : null;

    var contentHeight = qrSizeDots + gap + caseNumberPiece.height;
    if (patientPiece != null) contentHeight += patientPiece.height;
    if (doctorPiece != null) contentHeight += doctorPiece.height;

    // The whole block (QR + text) centred as one unit within the label's
    // height, rather than pinned to the top with whatever is left over
    // hanging blank at the bottom.
    final qrY = ((heightDots - contentHeight) / 2).round().clamp(
      0,
      heightDots,
    );

    final builder = BytesBuilder()
      ..add(ascii.encode('SIZE $widthMm mm,$heightMm mm\r\n'))
      ..add(ascii.encode('GAP 2 mm,0 mm\r\n'))
      ..add(ascii.encode('DIRECTION 1\r\n'))
      ..add(ascii.encode('CLS\r\n'))
      ..add(
        ascii.encode(
          'QRCODE $qrX,$qrY,L,$qrCellSize,A,0,"${_sanitize(qrPayload)}"\r\n',
        ),
      );

    var y = qrY + qrSizeDots + gap;
    caseNumberPiece.emit(builder, margin, y);
    y += caseNumberPiece.height;
    if (patientPiece != null) {
      patientPiece.emit(builder, margin, y);
      y += patientPiece.height;
    }
    if (doctorPiece != null) {
      doctorPiece.emit(builder, margin, y);
    }

    builder.add(ascii.encode('PRINT 1,1\r\n'));
    return builder.toBytes();
  }

  static Future<({int height, void Function(BytesBuilder, int, int) emit})>
  _prepareLabelText(
    String text, {
    required int boxWidth,
    required double fontSize,
    bool centered = false,
  }) async {
    final sanitized = _sanitize(text);
    if (TsplBitmapText.isAsciiSafe(sanitized)) {
      final font = fontSize >= 20 ? '3' : '2';
      const height = 40;
      final estWidth = sanitized.length * (fontSize >= 20 ? 18 : 14);
      final x = centered ? ((boxWidth - estWidth) / 2).round().clamp(0, boxWidth) : 0;
      return (
        height: height,
        emit: (builder, boxX, y) => builder.add(
          ascii.encode('TEXT ${boxX + x},$y,"$font",0,1,1,"$sanitized"\r\n'),
        ),
      );
    }

    final painter = TextPainter(
      text: TextSpan(
        text: sanitized,
        style: TextStyle(fontSize: fontSize, color: const Color(0xFF000000)),
      ),
      textAlign: centered ? TextAlign.center : TextAlign.left,
      textDirection: TextDirection.rtl,
    )..layout(maxWidth: boxWidth.toDouble());

    final height = painter.height.ceil().clamp(1, 4000);
    final packed = await TsplBitmapText.rasterize(
      painter: painter,
      width: boxWidth,
      height: height,
    );
    return (
      height: height,
      emit: (builder, boxX, y) => TsplBitmapText.writeBitmapCommand(
        builder,
        x: boxX,
        y: y,
        width: boxWidth,
        height: height,
        packed: packed,
      ),
    );
  }

  /// TSPL reads `"` as the end of a text field — one inside the value (a
  /// name with an inch mark, an odd case number) would truncate everything
  /// after it silently rather than error.
  static String _sanitize(String value) => value.replaceAll('"', "'");
}
