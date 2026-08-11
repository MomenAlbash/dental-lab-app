import 'dart:math' as math;

import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';
import 'package:flutter/material.dart';

/// FDI (ISO 3950) tooth numbers, arranged the way they're drawn on screen:
/// upper arch left-to-right, then lower arch left-to-right.
const List<int> _upperArch = [
  18, 17, 16, 15, 14, 13, 12, 11, //
  21, 22, 23, 24, 25, 26, 27, 28,
];
const List<int> _lowerArch = [
  48, 47, 46, 45, 44, 43, 42, 41, //
  31, 32, 33, 34, 35, 36, 37, 38,
];

/// Anatomical groups, read off the FDI number's second digit. Each group has
/// its own silhouette, which is what makes the chart readable as a mouth
/// rather than as a ring of identical cells.
enum _ToothKind { incisor, canine, premolar, molar }

_ToothKind _kindOf(int fdiNumber) => switch (fdiNumber % 10) {
  1 || 2 => _ToothKind.incisor,
  3 => _ToothKind.canine,
  4 || 5 => _ToothKind.premolar,
  _ => _ToothKind.molar,
};

/// A full-mouth FDI tooth chart: tap a tooth to add or remove it, and tap the
/// small circle between two selected neighbours to join them into a bridge
/// span (`connectedToToothNumber`).
class ToothChartWidget extends StatelessWidget {
  const ToothChartWidget({
    super.key,
    required this.teeth,
    required this.onChanged,
  });

  final List<ToothMarkModel> teeth;
  final ValueChanged<List<ToothMarkModel>> onChanged;

  bool _isSelected(int toothNumber) =>
      teeth.any((t) => t.toothNumber == toothNumber);

  /// Whether [b] is joined to its neighbour [a]. The link is stored on the
  /// later tooth in arch order, so a span reads in one direction only.
  bool _isConnected(int a, int b) =>
      teeth.any((t) => t.toothNumber == b && t.connectedToToothNumber == a);

  void _toggleTooth(int toothNumber) {
    final next = [...teeth];
    final index = next.indexWhere((t) => t.toothNumber == toothNumber);
    if (index >= 0) {
      next.removeAt(index);
      // Whatever pointed at the removed tooth loses its link, otherwise the
      // span would reference a tooth that is no longer on the restoration.
      for (var i = 0; i < next.length; i++) {
        if (next[i].connectedToToothNumber == toothNumber) {
          next[i] = next[i].copyWith(clearConnection: true);
        }
      }
    } else {
      next.add(ToothMarkModel(toothNumber: toothNumber));
    }
    onChanged(next);
  }

  /// Joins or separates two teeth that sit next to each other in the arch.
  void _toggleConnection(int a, int b) {
    final next = [...teeth];
    final index = next.indexWhere((t) => t.toothNumber == b);
    if (index < 0) return;

    next[index] = next[index].connectedToToothNumber == a
        ? next[index].copyWith(clearConnection: true)
        : next[index].copyWith(connectedToToothNumber: a);
    onChanged(next);
  }

  void _removeAt(int index) {
    final next = [...teeth];
    final removedNumber = next[index].toothNumber;
    next.removeAt(index);
    for (var i = 0; i < next.length; i++) {
      if (next[i].connectedToToothNumber == removedNumber) {
        next[i] = next[i].copyWith(clearConnection: true);
      }
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            borderRadius: BorderRadius.circular(AppRadius.glass),
            border: Border.all(color: glass.strokeColor),
            boxShadow: glass.shadows,
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1.5,
                child: _ArchView(
                  numbers: _upperArch,
                  isUpperArch: true,
                  isSelected: _isSelected,
                  isConnected: _isConnected,
                  onToothTap: _toggleTooth,
                  onConnectorTap: _toggleConnection,
                ),
              ),
              const _BiteLine(),
              AspectRatio(
                aspectRatio: 1.5,
                child: _ArchView(
                  numbers: _lowerArch,
                  isUpperArch: false,
                  isSelected: _isSelected,
                  isConnected: _isConnected,
                  onToothTap: _toggleTooth,
                  onConnectorTap: _toggleConnection,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (teeth.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              'اضغط على السن لإضافته، وعلى الدائرة بين سنّين لربطهما',
              textAlign: TextAlign.center,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 8,
            children: [
              for (var i = 0; i < teeth.length; i++)
                _ToothChip(
                  toothNumber: teeth[i].toothNumber,
                  connectedTo: teeth[i].connectedToToothNumber,
                  onRemove: () => _removeAt(i),
                ),
            ],
          ),
      ],
    );
  }
}

/// The dashed line separating the two arches — the bite line. Together with
/// each arch's midline it forms the quadrant crosshair a dental chart is read
/// against.
class _BiteLine extends StatelessWidget {
  const _BiteLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.lg,
      width: double.infinity,
      child: CustomPaint(
        painter: _BiteLinePainter(
          context.glass.onGlassMuted.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _BiteLinePainter extends CustomPainter {
  _BiteLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dash = 5.0;
    const gap = 4.0;
    final y = size.height / 2;

    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dash, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BiteLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Where every tooth of one arch sits, and how it is shaped.
///
/// Teeth are placed along an ellipse rather than a circle: a real arch is
/// wider than it is deep, and a circular ring was what made the old chart read
/// as a segmented donut.
class _ArchLayout {
  _ArchLayout({
    required this.size,
    required this.numbers,
    required this.isUpper,
  }) : center = Offset(
         size.width / 2,
         isUpper ? size.height * 0.94 : size.height * 0.06,
       ),
       radiusX = size.width * 0.43,
       radiusY = size.height * 0.80,
       unit = math.min(size.width / 16, size.height / 5.2);

  final Size size;
  final List<int> numbers;
  final bool isUpper;

  final Offset center;
  final double radiusX;
  final double radiusY;

  /// Base tooth size, derived from the box so the chart scales from a 360dp
  /// phone up to a tablet without hardcoded pixels.
  final double unit;

  int get count => numbers.length;

  /// Relative mesiodistal width per group — how much of the arch each tooth
  /// takes up. A molar is nearly twice a lateral incisor, which is what makes
  /// a real arch look the way it does.
  static double _relativeWidth(int fdiNumber) => switch (fdiNumber % 10) {
    1 => 0.92, // central incisor
    2 => 0.76, // lateral incisor
    3 => 0.84, // canine
    4 || 5 => 0.92, // premolars
    6 || 7 => 1.30, // first and second molars
    _ => 1.20, // third molar
  };

  late final List<double> _widths = [
    for (final number in numbers) _relativeWidth(number),
  ];

  late final double _totalWidth = _widths.reduce((a, b) => a + b);

  /// Length of the half-ellipse the crowns are laid along (Ramanujan's
  /// approximation, halved), used to turn relative widths into real ones.
  late final double _arcLength =
      math.pi *
      (3 * (radiusX + radiusY) -
          math.sqrt((3 * radiusX + radiusY) * (radiusX + 3 * radiusY))) /
      2;

  /// Parameter along the arch for the centre of tooth [i].
  ///
  /// Teeth are spaced by their own width rather than by equal angles: equal
  /// angles left gaps between the narrow front teeth and crowding at the back,
  /// where a real arch has the crowns touching all the way round.
  double _t(int i) {
    var before = 0.0;
    for (var k = 0; k < i; k++) {
      before += _widths[k];
    }
    return (before + _widths[i] / 2) / _totalWidth;
  }

  /// Centre of tooth [i]. The sweep runs from π to 2π, i.e. left → apex →
  /// right; the apex is the front of the mouth.
  Offset centerOf(int i) {
    final angle = math.pi + math.pi * _t(i);
    final dy = radiusY * math.sin(angle);
    return Offset(
      center.dx + radiusX * math.cos(angle),
      // Both arches curve away from the bite line in the middle of the box.
      center.dy + (isUpper ? dy : -dy),
    );
  }

  /// Rotation that keeps each tooth pointing outward from the centre of the
  /// arch, the way real teeth fan out.
  double rotationOf(int i) {
    final offset = centerOf(i) - center;
    return math.atan2(offset.dy, offset.dx) - math.pi / 2;
  }

  /// Width and height of tooth [i].
  ///
  /// The width is the tooth's own share of the arc — that is what makes the
  /// crowns sit against each other instead of floating apart. The height is a
  /// ratio of it, per group: incisors are tall and narrow seen from the biting
  /// surface, molars almost square.
  Size sizeOf(int i) {
    final width = _widths[i] / _totalWidth * _arcLength;
    final heightRatio = switch (_kindOf(numbers[i])) {
      _ToothKind.incisor => 1.45,
      _ToothKind.canine => 1.50,
      _ToothKind.premolar => 1.12,
      _ToothKind.molar => 0.95,
    };
    // 0.94 leaves a hairline between neighbours so the boundary stays visible.
    return Size(width * 0.94, width * heightRatio);
  }

  /// The tooth's outline, already positioned and rotated on the canvas.
  ///
  /// Crowns are drawn from the biting surface downward: incisors get a straight
  /// edge, the canine a point, premolars two cusps and molars four — which is
  /// what separates them at a glance.
  Path pathFor(int i) {
    final s = sizeOf(i);
    final w = s.width;
    final h = s.height;
    final kind = _kindOf(numbers[i]);

    // Local space: origin at the tooth's centre, +y toward the gum.
    final path = Path();
    final halfW = w / 2;
    final halfH = h / 2;

    switch (kind) {
      case _ToothKind.incisor:
        path
          ..moveTo(-halfW * 0.86, -halfH)
          ..lineTo(halfW * 0.86, -halfH)
          ..quadraticBezierTo(halfW, -halfH * 0.2, halfW * 0.82, halfH * 0.72)
          ..quadraticBezierTo(halfW * 0.6, halfH, 0, halfH)
          ..quadraticBezierTo(-halfW * 0.6, halfH, -halfW * 0.82, halfH * 0.72)
          ..quadraticBezierTo(-halfW, -halfH * 0.2, -halfW * 0.86, -halfH)
          ..close();
      case _ToothKind.canine:
        path
          ..moveTo(0, -halfH)
          ..quadraticBezierTo(
            halfW * 0.9,
            -halfH * 0.55,
            halfW * 0.86,
            halfH * 0.5,
          )
          ..quadraticBezierTo(halfW * 0.7, halfH, 0, halfH)
          ..quadraticBezierTo(-halfW * 0.7, halfH, -halfW * 0.86, halfH * 0.5)
          ..quadraticBezierTo(-halfW * 0.9, -halfH * 0.55, 0, -halfH)
          ..close();
      case _ToothKind.premolar:
        path
          ..moveTo(-halfW * 0.9, -halfH * 0.55)
          ..quadraticBezierTo(-halfW * 0.45, -halfH, 0, -halfH * 0.5)
          ..quadraticBezierTo(halfW * 0.45, -halfH, halfW * 0.9, -halfH * 0.55)
          ..quadraticBezierTo(halfW, halfH * 0.4, halfW * 0.6, halfH * 0.9)
          ..quadraticBezierTo(0, halfH * 1.05, -halfW * 0.6, halfH * 0.9)
          ..quadraticBezierTo(-halfW, halfH * 0.4, -halfW * 0.9, -halfH * 0.55)
          ..close();
      case _ToothKind.molar:
        path
          ..moveTo(-halfW * 0.92, -halfH * 0.5)
          ..quadraticBezierTo(
            -halfW * 0.66,
            -halfH,
            -halfW * 0.36,
            -halfH * 0.52,
          )
          ..quadraticBezierTo(0, -halfH * 0.86, halfW * 0.36, -halfH * 0.52)
          ..quadraticBezierTo(halfW * 0.66, -halfH, halfW * 0.92, -halfH * 0.5)
          ..quadraticBezierTo(
            halfW * 1.02,
            halfH * 0.45,
            halfW * 0.62,
            halfH * 0.92,
          )
          ..quadraticBezierTo(0, halfH * 1.06, -halfW * 0.62, halfH * 0.92)
          ..quadraticBezierTo(
            -halfW * 1.02,
            halfH * 0.45,
            -halfW * 0.92,
            -halfH * 0.5,
          )
          ..close();
    }

    final matrix = Matrix4.identity()
      ..translateByDouble(centerOf(i).dx, centerOf(i).dy, 0, 1)
      ..rotateZ(rotationOf(i));
    return path.transform(matrix.storage);
  }

  /// Where the join circle between teeth [i] and [i+1] sits — pushed inward,
  /// off the crowns, so it never covers a tooth it might be mistaken for.
  Offset connectorAt(int i) {
    final mid = Offset(
      (centerOf(i).dx + centerOf(i + 1).dx) / 2,
      (centerOf(i).dy + centerOf(i + 1).dy) / 2,
    );
    final inward = center - mid;
    final length = inward.distance;
    if (length == 0) return mid;
    return mid + inward / length * (unit * 0.72);
  }

  double get connectorRadius => math.max(unit * 0.24, 7);

  /// The tooth under [point], or null.
  int? toothAt(Offset point) {
    for (var i = 0; i < count; i++) {
      if (pathFor(i).contains(point)) return i;
    }
    return null;
  }

  /// The join circle under [point], as the index of the tooth before it.
  int? connectorAtPoint(Offset point) {
    for (var i = 0; i < count - 1; i++) {
      // A little larger than the drawn circle: it is a small target and sits
      // between two much bigger ones.
      if ((connectorAt(i) - point).distance <= connectorRadius + 6) return i;
    }
    return null;
  }
}

class _ArchView extends StatelessWidget {
  const _ArchView({
    required this.numbers,
    required this.isUpperArch,
    required this.isSelected,
    required this.isConnected,
    required this.onToothTap,
    required this.onConnectorTap,
  });

  final List<int> numbers;
  final bool isUpperArch;
  final bool Function(int) isSelected;
  final bool Function(int, int) isConnected;
  final ValueChanged<int> onToothTap;
  final void Function(int a, int b) onConnectorTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final layout = _ArchLayout(
          size: size,
          numbers: numbers,
          isUpper: isUpperArch,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final point = details.localPosition;

            // Connectors win: they sit between two crowns and are the smaller
            // target, so testing them first keeps them reachable.
            final connector = layout.connectorAtPoint(point);
            if (connector != null) {
              final a = numbers[connector];
              final b = numbers[connector + 1];
              if (isSelected(a) && isSelected(b)) {
                onConnectorTap(a, b);
                return;
              }
            }

            final tooth = layout.toothAt(point);
            if (tooth != null) onToothTap(numbers[tooth]);
          },
          child: CustomPaint(
            size: size,
            painter: _ArchPainter(
              layout: layout,
              isSelected: isSelected,
              isConnected: isConnected,
              // A painter has no BuildContext, so themed tones are resolved
              // here and handed in.
              accent: Theme.of(context).colorScheme.primary,
              gumColor: glass.toothGum,
              toothColor: glass.toothEnamel,
              outlineColor: glass.strokeColor,
              labelColor: glass.onGlassMuted,
            ),
          ),
        );
      },
    );
  }
}

class _ArchPainter extends CustomPainter {
  _ArchPainter({
    required this.layout,
    required this.isSelected,
    required this.isConnected,
    required this.accent,
    required this.gumColor,
    required this.toothColor,
    required this.outlineColor,
    required this.labelColor,
  });

  final _ArchLayout layout;
  final bool Function(int) isSelected;
  final bool Function(int, int) isConnected;
  final Color accent;
  final Color gumColor;
  final Color toothColor;
  final Color outlineColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintTissue(canvas);
    _paintMidline(canvas, size);

    for (var i = 0; i < layout.count; i++) {
      _paintTooth(canvas, i);
    }

    _paintConnectors(canvas);
  }

  /// The soft tissue behind the crowns: the palate (or the floor of the mouth)
  /// filling the inside of the horseshoe, and the gum as a deeper rim right
  /// behind the teeth.
  ///
  /// The filled inside is what makes the chart read as a mouth — an arch of
  /// crowns over an empty box reads as a diagram of nothing in particular.
  void _paintTissue(Canvas canvas) {
    final outer = <Offset>[];
    final inner = <Offset>[];

    for (var i = 0; i < layout.count; i++) {
      final toothCenter = layout.centerOf(i);
      final direction = toothCenter - layout.center;
      final length = direction.distance;
      if (length == 0) continue;
      final unitVector = direction / length;
      final half = layout.sizeOf(i).height / 2;
      outer.add(toothCenter + unitVector * (half * 0.55));
      inner.add(toothCenter - unitVector * (half * 1.35));
    }

    if (outer.isEmpty) return;

    // Palate / mouth floor: the inner boundary closed straight across the
    // opening of the horseshoe.
    final palate = Path()..moveTo(inner.first.dx, inner.first.dy);
    for (final point in inner.skip(1)) {
      palate.lineTo(point.dx, point.dy);
    }
    palate.close();
    canvas.drawPath(palate, Paint()..color = gumColor.withValues(alpha: 0.38));

    final band = Path()..moveTo(outer.first.dx, outer.first.dy);
    for (final point in outer.skip(1)) {
      band.lineTo(point.dx, point.dy);
    }
    for (final point in inner.reversed) {
      band.lineTo(point.dx, point.dy);
    }
    band.close();

    canvas.drawPath(band, Paint()..color = gumColor);
  }

  /// The dashed midline that splits the arch into its left and right
  /// quadrants — the same reference line a printed odontogram carries, and
  /// what tells the user which side of the mouth they are looking at.
  void _paintMidline(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = labelColor.withValues(alpha: 0.45)
      ..strokeWidth = 1;

    _dashedLine(
      canvas,
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 5.0;
    const gap = 4.0;

    final delta = to - from;
    final length = delta.distance;
    if (length == 0) return;
    final step = delta / length;

    var travelled = 0.0;
    while (travelled < length) {
      final end = math.min(travelled + dash, length);
      canvas.drawLine(from + step * travelled, from + step * end, paint);
      travelled = end + gap;
    }
  }

  void _paintTooth(Canvas canvas, int i) {
    final path = layout.pathFor(i);
    final selected = isSelected(layout.numbers[i]);

    canvas.drawPath(path, Paint()..color = selected ? accent : toothColor);
    _paintOcclusalSurface(canvas, i, selected);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 1.6 : 1
        ..color = selected ? accent : outlineColor,
    );

    _paintNumber(canvas, i, selected);
  }

  /// The chewing surface of the back teeth — the inner ring a premolar or
  /// molar shows when looked at from above. Front teeth present an edge, not a
  /// surface, so they get none.
  void _paintOcclusalSurface(Canvas canvas, int i, bool selected) {
    final kind = _kindOf(layout.numbers[i]);
    if (kind == _ToothKind.incisor || kind == _ToothKind.canine) return;

    final size = layout.sizeOf(i);
    final inset = kind == _ToothKind.molar ? 0.46 : 0.40;

    final surface = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: size.width * inset * 2,
            height: size.height * inset * 2,
          ),
          Radius.circular(size.width * 0.22),
        ),
      );

    final matrix = Matrix4.identity()
      ..translateByDouble(layout.centerOf(i).dx, layout.centerOf(i).dy, 0, 1)
      ..rotateZ(layout.rotationOf(i));

    canvas.drawPath(
      surface.transform(matrix.storage),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        // Selected crowns are a solid accent block; a darker inner line would
        // read as damage rather than anatomy, so it lightens instead.
        ..color = selected
            ? toothColor.withValues(alpha: 0.55)
            : outlineColor.withValues(alpha: 0.65),
    );
  }

  /// Numbers sit outside the crowns, upright, so they stay readable instead of
  /// rotating with the tooth.
  void _paintNumber(Canvas canvas, int i, bool selected) {
    final direction = layout.centerOf(i) - layout.center;
    final length = direction.distance;
    if (length == 0) return;

    final position =
        layout.centerOf(i) +
        direction / length * (layout.sizeOf(i).height * 0.62 + 7);

    final painter = TextPainter(
      text: TextSpan(
        text: '${layout.numbers[i]}',
        style: TextStyle(
          fontSize: math.max(layout.unit * 0.34, 8),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? accent : labelColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      position - Offset(painter.width / 2, painter.height / 2),
    );
  }

  /// One circle per gap between two *selected* neighbours: filled once they
  /// are joined, hollow while they are not. Offering it only where both teeth
  /// are on the restoration keeps the chart from sprouting 15 dots per arch.
  void _paintConnectors(Canvas canvas) {
    for (var i = 0; i < layout.count - 1; i++) {
      final a = layout.numbers[i];
      final b = layout.numbers[i + 1];
      if (!isSelected(a) || !isSelected(b)) continue;

      final point = layout.connectorAt(i);
      final joined = isConnected(a, b);
      final radius = layout.connectorRadius;

      if (joined) {
        // The bar makes the span itself visible, not just its endpoints.
        canvas.drawLine(
          layout.centerOf(i),
          layout.centerOf(i + 1),
          Paint()
            ..color = accent
            ..strokeWidth = radius * 0.7
            ..strokeCap = StrokeCap.round,
        );
      }

      canvas
        ..drawCircle(
          point,
          radius,
          Paint()..color = joined ? accent : toothColor,
        )
        ..drawCircle(
          point,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = joined ? accent : outlineColor,
        );

      if (!joined) {
        // A plus sign says "these can be joined" without any text.
        final arm = radius * 0.45;
        final plus = Paint()
          ..color = labelColor
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round;
        canvas
          ..drawLine(point - Offset(arm, 0), point + Offset(arm, 0), plus)
          ..drawLine(point - Offset(0, arm), point + Offset(0, arm), plus);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArchPainter oldDelegate) => true;
}

/// One selected tooth below the chart, with its bridge link if it has one.
class _ToothChip extends StatelessWidget {
  const _ToothChip({
    required this.toothNumber,
    required this.connectedTo,
    required this.onRemove,
  });

  final int toothNumber;
  final int? connectedTo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.only(left: 4, right: 10, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close, size: 14, color: glass.onGlassMuted),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            connectedTo == null
                ? '$toothNumber'
                : '$toothNumber ↔ $connectedTo',
            style: AppTextStyles.font12RegularHint.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}
