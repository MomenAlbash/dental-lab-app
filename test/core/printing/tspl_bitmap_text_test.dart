import 'dart:typed_data';

import 'package:dental_lab_app/core/printing/tspl_bitmap_text.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isAsciiSafe', () {
    test('true for plain Latin/digits', () {
      expect(TsplBitmapText.isAsciiSafe('CS-100 x2'), isTrue);
    });

    test('false for Arabic', () {
      expect(TsplBitmapText.isAsciiSafe('مريض'), isFalse);
    });

    test('false for a lone non-ASCII symbol', () {
      expect(TsplBitmapText.isAsciiSafe('×'), isFalse);
    });
  });

  group('rasterize', () {
    test('packs one byte per 8 pixels of width, per row', () async {
      final painter = TextPainter(
        text: const TextSpan(
          text: 'مريض',
          style: TextStyle(fontSize: 16, color: Color(0xFF000000)),
        ),
        textDirection: TextDirection.rtl,
      )..layout(maxWidth: 200);

      const width = 40;
      final height = painter.height.ceil();
      final packed = await TsplBitmapText.rasterize(
        painter: painter,
        width: width,
        height: height,
      );

      final widthBytes = (width + 7) ~/ 8;
      expect(packed.length, widthBytes * height);
    });

    test(
      'an all-whitespace line packs to all-0xFF (blank) bytes',
      () async {
        // Bit convention confirmed on real hardware: 0 = print, 1 = blank —
        // the reverse of the documented TSC spec. An unprinted line must
        // pack to all-ones, not all-zero, or it comes out a solid black bar.
        final painter = TextPainter(
          text: const TextSpan(
            text: '   ',
            style: TextStyle(fontSize: 16, color: Color(0xFF000000)),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 60);

        final packed = await TsplBitmapText.rasterize(
          painter: painter,
          width: 60,
          height: painter.height.ceil(),
        );

        expect(packed.every((byte) => byte == 0xFF), isTrue);
      },
    );
  });

  group('writeBitmapCommand', () {
    test('embeds the packed bytes verbatim between header and CRLF', () {
      final builder = BytesBuilder();
      final packed = Uint8List.fromList([0xFF, 0x00, 0x81]);

      TsplBitmapText.writeBitmapCommand(
        builder,
        x: 10,
        y: 20,
        width: 24,
        height: 1,
        packed: packed,
      );

      final bytes = builder.toBytes();
      final header = String.fromCharCodes(bytes.take(bytes.length - 5));
      expect(header, 'BITMAP 10,20,3,1,0,');
      expect(bytes.sublist(bytes.length - 5, bytes.length - 2), packed);
      expect(bytes.sublist(bytes.length - 2), [13, 10]);
    });
  });
}
