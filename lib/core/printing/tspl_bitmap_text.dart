import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Rasterizes one text block into a TSPL `BITMAP` command.
///
/// Confirmed on real hardware: these printers' built-in bitmap font has no
/// Arabic glyphs. Sending Arabic through TSPL's own `TEXT` command gets the
/// UTF-8 bytes reinterpreted through the printer's default (Latin) codepage
/// and prints unrelated symbols. Rendering the line as an image through
/// Flutter's own text layout is what actually shapes and reorders Arabic
/// correctly — the printer just prints dots, no font of its own involved.
///
/// ASCII-only text skips this path entirely (see the `_isAsciiSafe` callers
/// in [LabelPrinterService.buildCaseLabel] and `CaseTicketRenderer`) since a
/// bitmap is dozens of times heavier to transmit over BLE than the
/// equivalent `TEXT` command, and plain ASCII already prints correctly with
/// either.
class TsplBitmapText {
  const TsplBitmapText._();

  /// Paints [painter] (already laid out by the caller) onto a white
  /// [width]x[height] canvas and packs it into TSPL's 1-bit-per-pixel,
  /// MSB-first, byte-aligned-per-row bitmap format.
  ///
  /// **Bit convention confirmed on real hardware: `0` = print (black), `1`
  /// = blank** — the reverse of the documented TSC `BITMAP` spec (which
  /// says `1` prints). Sending the documented convention printed solid
  /// black rectangles with the glyphs cut out in white. The buffer
  /// therefore starts all-`0xFF` (blank) and only ink pixels get their bit
  /// cleared, rather than starting at zero and setting ink bits — that also
  /// makes row padding past the real text width blank by construction,
  /// since the printer prints every bit of a byte-aligned row regardless of
  /// where the source image actually ended.
  static Future<Uint8List> rasterize({
    required TextPainter painter,
    required int width,
    required int height,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = const Color(0xFFFFFFFF),
    );
    painter.paint(canvas, Offset.zero);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    image.dispose();

    final widthBytes = (width + 7) ~/ 8;
    final packed = Uint8List(widthBytes * height)
      ..fillRange(0, widthBytes * height, 0xFF);
    if (byteData == null) return packed;

    final pixels = byteData.buffer.asUint8List();
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final offset = (y * width + x) * 4;
        final luminance = (pixels[offset] + pixels[offset + 1] + pixels[offset + 2]) / 3;
        // Anything but near-white counts as ink — anti-aliased glyph edges
        // are mid-gray and should still print, or thin strokes vanish.
        if (luminance < 200) {
          packed[y * widthBytes + (x >> 3)] &= ~(0x80 >> (x & 7));
        }
      }
    }
    return packed;
  }

  /// Writes a full `BITMAP x,y,widthBytes,height,mode,<data>` command
  /// (mode 0 = overwrite) into [builder], with [packed] embedded verbatim
  /// as raw binary — it must never pass through a String/UTF-8 round trip,
  /// which would corrupt bytes that happen to collide with multi-byte UTF-8
  /// sequences.
  static void writeBitmapCommand(
    BytesBuilder builder, {
    required int x,
    required int y,
    required int width,
    required int height,
    required Uint8List packed,
  }) {
    final widthBytes = (width + 7) ~/ 8;
    builder.add(ascii.encode('BITMAP $x,$y,$widthBytes,$height,0,'));
    builder.add(packed);
    builder.add(ascii.encode('\r\n'));
  }

  /// True when every code unit fits in the printer's native codepage —
  /// the cheap, already-correct path that does not need rasterizing.
  static bool isAsciiSafe(String value) =>
      value.codeUnits.every((unit) => unit < 128);
}
