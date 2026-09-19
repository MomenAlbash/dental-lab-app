import 'package:flutter/material.dart';

/// The painted gap between two rows of a top-to-bottom graph: a stem down from
/// each node above, a bus across, and a stem down into each node below.
///
/// Drawing the same shape for a fan-out, a merge and a straight run means a
/// route reads by one rule everywhere — a 1→1 step is simply a fork with one
/// arm. Purely vertical stems mean it needs no mirroring under RTL.
///
/// Shared because both boards that draw a route — the live case plan and the
/// restoration-route editor — need the identical shape, and two copies would
/// drift.
class GraphFork extends StatelessWidget {
  const GraphFork({
    super.key,
    required this.fromCount,
    required this.toCount,
    required this.nodeWidth,
    required this.color,
    this.gutter = 0,
    this.height = 30,
  });

  /// Columns in the row above and the row below.
  final int fromCount;
  final int toCount;

  /// Width of one node, so the stems land on the nodes' centres.
  final double nodeWidth;

  /// Horizontal padding around each node, counted into the column width.
  final double gutter;

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final columns = fromCount > toCount ? fromCount : toCount;

    return SizedBox(
      width: columns * (nodeWidth + gutter * 2),
      height: height,
      child: CustomPaint(
        painter: _ForkPainter(
          fromCount: fromCount,
          toCount: toCount,
          color: color,
        ),
      ),
    );
  }
}

class _ForkPainter extends CustomPainter {
  const _ForkPainter({
    required this.fromCount,
    required this.toCount,
    required this.color,
  });

  final int fromCount;
  final int toCount;
  final Color color;

  /// Centres of [count] evenly spaced columns across [width].
  List<double> _centres(int count, double width) {
    final slot = width / count;
    return [for (var i = 0; i < count; i++) slot * i + slot / 2];
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (fromCount == 0 || toCount == 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final from = _centres(fromCount, size.width);
    final to = _centres(toCount, size.width);
    final midY = size.height / 2;

    for (final x in from) {
      canvas.drawLine(Offset(x, 0), Offset(x, midY), paint);
    }
    for (final x in to) {
      canvas.drawLine(Offset(x, midY), Offset(x, size.height), paint);
    }

    // The crossbar joining them, skipped when both rows sit on the same single
    // column — a straight run needs no bar.
    final all = [...from, ...to];
    final left = all.reduce((a, b) => a < b ? a : b);
    final right = all.reduce((a, b) => a > b ? a : b);
    if (right - left > 0.5) {
      canvas.drawLine(Offset(left, midY), Offset(right, midY), paint);
    }
  }

  @override
  bool shouldRepaint(_ForkPainter old) =>
      old.fromCount != fromCount ||
      old.toCount != toCount ||
      old.color != color;
}
