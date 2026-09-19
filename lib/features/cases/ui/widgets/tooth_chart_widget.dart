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
    this.takenTeeth = const {},
  });

  final List<ToothMarkModel> teeth;
  final ValueChanged<List<ToothMarkModel>> onChanged;

  /// Teeth already claimed by another restoration on the same case.
  ///
  /// They are drawn as spoken for and refuse a tap: one tooth cannot be two
  /// restorations, and letting it be picked twice files a case whose piece
  /// counts do not add up to the mouth it describes.
  final Set<int> takenTeeth;

  bool _isSelected(int toothNumber) =>
      teeth.any((t) => t.toothNumber == toothNumber);

  bool _isTaken(int toothNumber) => takenTeeth.contains(toothNumber);

  /// Whether [b] is joined to its neighbour [a]. The link is stored on the
  /// later tooth in arch order, so a span reads in one direction only.
  bool _isConnected(int a, int b) =>
      teeth.any((t) => t.toothNumber == b && t.connectedToToothNumber == a);

  void _toggleTooth(int toothNumber) {
    // Guarded here as well as in the hit test: the chart is the only thing
    // standing between a taken tooth and a second restoration on it.
    if (_isTaken(toothNumber)) return;

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
          child: AspectRatio(
            // Taller than wide: the two arches together form one closed oval,
            // the way a full-mouth scan is presented.
            aspectRatio: 0.78,
            child: _MouthView(
              isSelected: _isSelected,
              isTaken: _isTaken,
              isConnected: _isConnected,
              onToothTap: _toggleTooth,
              onConnectorTap: _toggleConnection,
            ),
          ),
        ),
        if (takenTeeth.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'الأسنان الباهتة محجوزة لتعويض آخر في هذه الحالة',
              textAlign: TextAlign.center,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
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

/// How much of each half-ellipse is left empty at the bite line, as a fraction
/// of the sweep. Without it the two third molars of a side (18 and 48) would
/// touch, and the oval would read as one continuous ring of 32 teeth instead
/// of two arches meeting.
const double _archSweepInset = 0.018;

/// Where every tooth of one arch sits, and how it is shaped.
///
/// Teeth are placed along an ellipse rather than a circle: a real arch is
/// wider than it is deep, and a circular ring was what made the old chart read
/// as a segmented donut.
class _ArchLayout {
  /// Both arches of a chart share one [center] and one pair of radii: that is
  /// what turns two half-ellipses into the single oval of a full-mouth view.
  _ArchLayout({
    required this.numbers,
    required this.isUpper,
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.unit,
  });

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
    final sweep = math.pi * (1 - 2 * _archSweepInset);
    final angle = math.pi + math.pi * _archSweepInset + sweep * _t(i);
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
      _ToothKind.incisor => 1.55,
      _ToothKind.canine => 1.60,
      _ToothKind.premolar => 1.30,
      _ToothKind.molar => 1.10,
    };
    // Exactly its own share of the arc: neighbouring crowns meet at their
    // contact points the way they do in a real arch, instead of sitting apart
    // with the gum showing between every pair. Every crown is outlined in a
    // second pass, so the boundary stays readable without a gap.
    return Size(width, width * heightRatio);
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
    return mid + inward / length * insetOf(i);
  }

  /// How far inside the arch the join circle and the bridge bar sit for tooth
  /// [i]: clear of the crown itself, out on the gum, so neither ever covers a
  /// tooth's number.
  double insetOf(int i) => sizeOf(i).height * 0.5 + connectorRadius * 0.95;

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

/// Both arches on one canvas, laid out around a shared centre so they close
/// into a single oval — the shape a full-mouth view is read in.
class _MouthView extends StatelessWidget {
  const _MouthView({
    required this.isSelected,
    required this.isTaken,
    required this.isConnected,
    required this.onToothTap,
    required this.onConnectorTap,
  });

  final bool Function(int) isSelected;
  final bool Function(int) isTaken;
  final bool Function(int, int) isConnected;
  final ValueChanged<int> onToothTap;
  final void Function(int a, int b) onConnectorTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        // The oval is centred in the box; the margin left around it is the
        // room the crowns themselves need, since they straddle the ellipse.
        final center = Offset(size.width / 2, size.height / 2);
        final radiusX = size.width * 0.38;
        final radiusY = size.height * 0.42;
        final unit = math.min(size.width / 16, size.height / 10.4);

        _ArchLayout archOf(List<int> numbers, {required bool isUpper}) =>
            _ArchLayout(
              numbers: numbers,
              isUpper: isUpper,
              center: center,
              radiusX: radiusX,
              radiusY: radiusY,
              unit: unit,
            );

        final upper = archOf(_upperArch, isUpper: true);
        final lower = archOf(_lowerArch, isUpper: false);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final point = details.localPosition;

            for (final layout in [upper, lower]) {
              // Connectors win: they sit between two crowns and are the
              // smaller target, so testing them first keeps them reachable.
              final connector = layout.connectorAtPoint(point);
              if (connector != null) {
                final a = layout.numbers[connector];
                final b = layout.numbers[connector + 1];
                if (isSelected(a) && isSelected(b)) {
                  onConnectorTap(a, b);
                  return;
                }
              }
            }

            for (final layout in [upper, lower]) {
              final tooth = layout.toothAt(point);
              if (tooth != null) {
                // A tooth spoken for by another restoration swallows the tap
                // rather than passing it to whatever is underneath.
                if (isTaken(layout.numbers[tooth])) return;
                onToothTap(layout.numbers[tooth]);
                return;
              }
            }
          },
          child: CustomPaint(
            size: size,
            painter: _MouthPainter(
              arches: [upper, lower],
              isSelected: isSelected,
              isTaken: isTaken,
              isConnected: isConnected,
              // A painter has no BuildContext, so themed tones are resolved
              // here and handed in.
              accent: Theme.of(context).colorScheme.primary,
              gumColor: glass.toothGum,
              toothColor: glass.toothEnamel,
              // Deliberately stronger than the app's hairline stroke: enamel
              // is nearly white on a nearly white pane, and once the crowns
              // touch, the outline is the only thing separating one tooth
              // from the next.
              outlineColor: glass.onGlassMuted.withValues(alpha: 0.55),
              labelColor: glass.onGlassMuted,
              // A distinct hue rather than a blend of labelColor: in dark
              // theme labelColor sits too close to toothColor's own
              // brightness, so a taken tooth barely differed from a free one.
              takenColor: glass.toothGum,
            ),
          ),
        );
      },
    );
  }
}

class _MouthPainter extends CustomPainter {
  _MouthPainter({
    required this.arches,
    required this.isSelected,
    required this.isTaken,
    required this.isConnected,
    required this.accent,
    required this.gumColor,
    required this.toothColor,
    required this.outlineColor,
    required this.labelColor,
    required this.takenColor,
  });

  /// Upper arch first, then lower — painted in that order so they stack the
  /// way they sit in the mouth.
  final List<_ArchLayout> arches;
  final bool Function(int) isSelected;
  final bool Function(int) isTaken;
  final bool Function(int, int) isConnected;
  final Color accent;
  final Color gumColor;
  final Color toothColor;
  final Color outlineColor;
  final Color labelColor;
  final Color takenColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final layout in arches) {
      _paintTissue(canvas, layout);
    }

    _paintQuadrantLines(canvas, size);

    // Painted in layers, not tooth by tooth, and the order is the whole point:
    // the crowns touch, so anything drawn after a neighbour would be buried
    // under that neighbour's fill. Bridge bars go under the crowns, the fills
    // next, then the lines, and the numbers last of all — nothing is ever
    // drawn on top of a tooth's number.
    for (final layout in arches) {
      _paintSpans(canvas, layout);
    }
    for (final layout in arches) {
      for (var i = 0; i < layout.count; i++) {
        _paintToothFill(canvas, layout, i);
      }
    }
    for (final layout in arches) {
      for (var i = 0; i < layout.count; i++) {
        _paintToothDetail(canvas, layout, i);
      }
      _paintConnectors(canvas, layout);
    }
    for (final layout in arches) {
      for (var i = 0; i < layout.count; i++) {
        _paintNumber(canvas, layout, i);
      }
    }
  }

  /// The soft tissue behind the crowns: the palate (or the floor of the mouth)
  /// filling the inside of the horseshoe, and the gum as a deeper rim right
  /// behind the teeth.
  ///
  /// The filled inside is what makes the chart read as a mouth — an arch of
  /// crowns over an empty box reads as a diagram of nothing in particular.
  void _paintTissue(Canvas canvas, _ArchLayout layout) {
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

  /// The crosshair that splits the oval into the four quadrants (1x, 2x, 3x,
  /// 4x): the midline between the two central incisors, and the bite line
  /// between the arches. It is the same reference an odontogram is printed
  /// with, and it is what tells the user which side of which jaw they are
  /// looking at.
  void _paintQuadrantLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = labelColor.withValues(alpha: 0.45)
      ..strokeWidth = 1;

    final center = arches.first.center;

    _dashedLine(
      canvas,
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
    _dashedLine(
      canvas,
      Offset(0, center.dy),
      Offset(size.width, center.dy),
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

  void _paintToothFill(Canvas canvas, _ArchLayout layout, int i) {
    final number = layout.numbers[i];
    final Color fill;
    if (isSelected(number)) {
      fill = accent;
    } else if (isTaken(number)) {
      // Blended from a distinct hue (the gum's own tone) rather than the
      // muted label color: in dark theme, labelColor sits close in
      // brightness to toothColor, so that blend barely read as different
      // from a free tooth.
      fill = Color.alphaBlend(takenColor.withValues(alpha: 0.45), toothColor);
    } else {
      fill = toothColor;
    }

    canvas.drawPath(layout.pathFor(i), Paint()..color = fill);
  }

  /// The crown's outline, and nothing else on the crown.
  ///
  /// The occlusal grooves were drawn here once. They crossed the tooth's
  /// number, and a number that has to be read through a line is worse than a
  /// crown that shows no anatomy: the silhouette already separates a molar
  /// from an incisor.
  void _paintToothDetail(Canvas canvas, _ArchLayout layout, int i) {
    final selected = isSelected(layout.numbers[i]);

    canvas.drawPath(
      layout.pathFor(i),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 1.6 : 1
        ..color = selected ? accent : outlineColor,
    );
  }

  /// The FDI number is written on the crown itself, the way a scanner's
  /// full-mouth view labels its teeth — and always upright, so it stays
  /// readable instead of rotating with the tooth.
  ///
  /// Painted after everything else, for every tooth: the number is the one
  /// thing a crown must always show, and a bridge bar crossing it used to wipe
  /// it out exactly when the case got harder to read.
  void _paintNumber(Canvas canvas, _ArchLayout layout, int i) {
    final selected = isSelected(layout.numbers[i]);
    final painter = TextPainter(
      text: TextSpan(
        text: '${layout.numbers[i]}',
        style: TextStyle(
          fontSize: math.max(layout.unit * 0.36, 8),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          // On a selected crown the accent is the fill, so the label flips to
          // the enamel tone to stay legible.
          color: selected ? toothColor : labelColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final position = layout.centerOf(i);
    painter.paint(
      canvas,
      position - Offset(painter.width / 2, painter.height / 2),
    );
  }

  /// The bar that makes a bridge span visible as one piece rather than as two
  /// separate crowns.
  ///
  /// It runs beside the crowns, on the tongue side, and is painted before
  /// them: drawn across the middle of the teeth it covered their numbers,
  /// which is the one thing on a chart that must never be hidden.
  void _paintSpans(Canvas canvas, _ArchLayout layout) {
    for (var i = 0; i < layout.count - 1; i++) {
      final a = layout.numbers[i];
      final b = layout.numbers[i + 1];
      if (!isSelected(a) || !isSelected(b) || !isConnected(a, b)) continue;

      canvas.drawLine(
        _towardCenter(layout, i),
        _towardCenter(layout, i + 1),
        Paint()
          ..color = accent
          ..strokeWidth = layout.connectorRadius * 1.1
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// The point on tooth [i] that the span bar passes through: pulled off the
  /// crown toward the inside of the arch, where the join circle also sits.
  Offset _towardCenter(_ArchLayout layout, int i) {
    final toothCenter = layout.centerOf(i);
    final inward = layout.center - toothCenter;
    final length = inward.distance;
    if (length == 0) return toothCenter;
    return toothCenter + inward / length * layout.insetOf(i);
  }

  /// One circle per gap between two *selected* neighbours: filled once they
  /// are joined, hollow while they are not. Offering it only where both teeth
  /// are on the restoration keeps the chart from sprouting 15 dots per arch.
  void _paintConnectors(Canvas canvas, _ArchLayout layout) {
    for (var i = 0; i < layout.count - 1; i++) {
      final a = layout.numbers[i];
      final b = layout.numbers[i + 1];
      if (!isSelected(a) || !isSelected(b)) continue;

      final point = layout.connectorAt(i);
      final joined = isConnected(a, b);
      final radius = layout.connectorRadius;

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
  bool shouldRepaint(covariant _MouthPainter oldDelegate) => true;
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
