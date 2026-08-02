import 'dart:math' as math;

import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';
import 'package:flutter/material.dart';

/// FDI (ISO 3950) tooth numbers, arranged the way they're drawn on screen:
/// upper arch left-to-right, then lower arch left-to-right.
const List<int> _upperArch = [
  18, 17, 16, 15, 14, 13, 12, 11,
  21, 22, 23, 24, 25, 26, 27, 28,
];
const List<int> _lowerArch = [
  48, 47, 46, 45, 44, 43, 42, 41,
  31, 32, 33, 34, 35, 36, 37, 38,
];

/// A full-mouth FDI tooth chart drawn as one continuous arch outline per jaw
/// (like a dental odontogram): tap a tooth to add/remove it from [teeth].
/// Selected teeth are listed below the chart in the order they were picked,
/// where a link icon between two consecutive teeth toggles whether the later
/// one is connected to the one right before it (bridge span) — see
/// [ToothMarkModel.connectedToToothNumber].
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

  void _toggleTooth(int toothNumber) {
    final next = [...teeth];
    final index = next.indexWhere((t) => t.toothNumber == toothNumber);
    if (index >= 0) {
      final removedNumber = next[index].toothNumber;
      next.removeAt(index);
      // Re-link whatever pointed to the removed tooth to whatever it pointed
      // to, so the chain doesn't break in the middle.
      for (var i = 0; i < next.length; i++) {
        if (next[i].connectedToToothNumber == removedNumber) {
          next[i] = next[i].copyWith(clearConnection: true);
        }
      }
    } else {
      next.add(ToothMarkModel(toothNumber: toothNumber));
    }
    onChanged(next);
  }

  void _toggleConnection(int index) {
    if (index <= 0 || index >= teeth.length) return;
    final next = [...teeth];
    final current = next[index];
    final previousNumber = next[index - 1].toothNumber;
    final isConnected = current.connectedToToothNumber == previousNumber;
    next[index] = isConnected
        ? current.copyWith(clearConnection: true)
        : current.copyWith(connectedToToothNumber: previousNumber);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColorsManger.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColorsManger.border),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1.55,
                child: _ArchArc(
                  numbers: _upperArch,
                  isSelected: _isSelected,
                  onTap: _toggleTooth,
                  isUpperArch: true,
                ),
              ),
              AspectRatio(
                aspectRatio: 2.6,
                child: _ArchDivider(),
              ),
              AspectRatio(
                aspectRatio: 1.55,
                child: _ArchArc(
                  numbers: _lowerArch,
                  isSelected: _isSelected,
                  onTap: _toggleTooth,
                  isUpperArch: false,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (teeth.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'اضغط على السن بالمخطط لإضافته',
              textAlign: TextAlign.center,
              style: AppTextStyles.font12RegularHint,
            ),
          )
        else
          Wrap(
            spacing: 4,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < teeth.length; i++) ...[
                if (i > 0)
                  _ConnectorToggle(
                    isConnected:
                        teeth[i].connectedToToothNumber ==
                        teeth[i - 1].toothNumber,
                    onTap: () => _toggleConnection(i),
                  ),
                _ToothChip(
                  toothNumber: teeth[i].toothNumber,
                  onRemove: () => _removeAt(i),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// Polar geometry shared by the painter and the tap hit-tester for one arch.
class _ArchGeometry {
  _ArchGeometry({
    required this.center,
    required this.innerR,
    required this.outerR,
    required this.startAngle,
    required this.sweep,
    required this.count,
  });

  final Offset center;
  final double innerR;
  final double outerR;
  final double startAngle;
  final double sweep;
  final int count;

  double angleForIndex(int i) =>
      startAngle - sweep * (count <= 1 ? 0.5 : i / (count - 1));

  /// The angular boundary between tooth [i-1] and tooth [i] (index 0 and
  /// [count] are the arc's outer edges).
  List<double> get boundaries {
    final angles = List.generate(count, angleForIndex);
    final b = List<double>.filled(count + 1, 0);
    b[0] = startAngle;
    b[count] = startAngle - sweep;
    for (var k = 1; k < count; k++) {
      b[k] = (angles[k - 1] + angles[k]) / 2;
    }
    return b;
  }

  /// Returns the tapped tooth index, or `null` if outside the ring. Works
  /// regardless of [sweep]'s sign (the upper and lower arches sweep in
  /// opposite directions).
  int? indexAt(Offset local) {
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < innerR - 8 || dist > outerR + 8) return null;

    final lo = math.min(startAngle, startAngle - sweep);
    final hi = math.max(startAngle, startAngle - sweep);

    var angle = math.atan2(dy, dx);
    while (angle > hi + 0.01) {
      angle -= math.pi * 2;
    }
    while (angle < lo - 0.01) {
      angle += math.pi * 2;
    }
    if (angle < lo - 0.01 || angle > hi + 0.01) return null;

    final b = boundaries;
    for (var i = 0; i < count; i++) {
      final segLo = math.min(b[i], b[i + 1]);
      final segHi = math.max(b[i], b[i + 1]);
      if (angle >= segLo - 0.001 && angle <= segHi + 0.001) return i;
    }
    return null;
  }
}

/// One arch drawn as a single continuous ring segment (odontogram style),
/// with thin radial dividers between teeth and the tooth numbers placed
/// upright along the ring.
class _ArchArc extends StatelessWidget {
  const _ArchArc({
    required this.numbers,
    required this.isSelected,
    required this.onTap,
    required this.isUpperArch,
  });

  final List<int> numbers;
  final bool Function(int) isSelected;
  final ValueChanged<int> onTap;
  final bool isUpperArch;

  _ArchGeometry _geometryFor(Size size) {
    final outerR = size.width * 0.5;
    const ringThickness = 34.0;
    final innerR = outerR - ringThickness;
    // Front teeth (t=0.5) sit at the apex, away from the bite line; back
    // teeth (t=0/1) dip toward it. Values are pre-derived so they agree with
    // both the filled arc (`Path.arcTo`, Flutter's clockwise-positive,
    // y-down convention) and `_pointAt` below, which uses that same
    // convention directly.
    const startDeg = 190.0;
    const sweepDeg = 200.0;
    final apexY = outerR + 6;
    final center = isUpperArch
        ? Offset(size.width / 2, apexY)
        : Offset(size.width / 2, size.height - apexY);

    return _ArchGeometry(
      center: center,
      innerR: innerR,
      outerR: outerR,
      startAngle: (isUpperArch ? -startDeg : startDeg) * math.pi / 180,
      sweep: (isUpperArch ? -sweepDeg : sweepDeg) * math.pi / 180,
      count: numbers.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final geometry = _geometryFor(size);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final index = geometry.indexAt(details.localPosition);
            if (index != null) onTap(numbers[index]);
          },
          child: CustomPaint(
            size: size,
            painter: _ArchPainter(
              geometry: geometry,
              numbers: numbers,
              isSelected: isSelected,
            ),
          ),
        );
      },
    );
  }
}

class _ArchPainter extends CustomPainter {
  _ArchPainter({
    required this.geometry,
    required this.numbers,
    required this.isSelected,
  });

  final _ArchGeometry geometry;
  final List<int> numbers;
  final bool Function(int) isSelected;

  /// Flutter's arc/angle convention: 0 rad points along +x, and positive
  /// angles rotate clockwise (since y grows downward on screen) — matches
  /// `Path.arcTo` directly, with no sign flip needed.
  Offset _pointAt(double angle, double radius) {
    return geometry.center +
        Offset(radius * math.cos(angle), radius * math.sin(angle));
  }

  Path _ringPath() {
    final outerRect = Rect.fromCircle(
      center: geometry.center,
      radius: geometry.outerR,
    );
    final innerRect = Rect.fromCircle(
      center: geometry.center,
      radius: geometry.innerR,
    );
    return Path()
      ..arcTo(outerRect, geometry.startAngle, -geometry.sweep, true)
      ..arcTo(innerRect, geometry.startAngle - geometry.sweep, geometry.sweep, false)
      ..close();
  }

  Path _wedgePath(int index) {
    final b = geometry.boundaries;
    final a0 = b[index];
    final a1 = b[index + 1];
    final outerRect = Rect.fromCircle(
      center: geometry.center,
      radius: geometry.outerR,
    );
    final innerRect = Rect.fromCircle(
      center: geometry.center,
      radius: geometry.innerR,
    );
    return Path()
      ..arcTo(outerRect, a0, a1 - a0, true)
      ..arcTo(innerRect, a1, a0 - a1, false)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Base ring (unselected teeth).
    canvas.drawPath(
      _ringPath(),
      Paint()
        ..color = AppColorsManger.moreLightGray
        ..style = PaintingStyle.fill,
    );

    // Selected teeth get a colored wedge on top.
    for (var i = 0; i < numbers.length; i++) {
      if (isSelected(numbers[i])) {
        canvas.drawPath(
          _wedgePath(i),
          Paint()
            ..color = AppColorsManger.primary
            ..style = PaintingStyle.fill,
        );
      }
    }

    // Outer boundary.
    canvas.drawPath(
      _ringPath(),
      Paint()
        ..color = AppColorsManger.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Radial dividers between adjacent teeth.
    final b = geometry.boundaries;
    final dividerPaint = Paint()
      ..color = AppColorsManger.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var k = 1; k < numbers.length; k++) {
      canvas.drawLine(
        _pointAt(b[k], geometry.innerR),
        _pointAt(b[k], geometry.outerR),
        dividerPaint,
      );
    }

    // Numbers, upright, centered in each wedge.
    for (var i = 0; i < numbers.length; i++) {
      final angle = geometry.angleForIndex(i);
      final point = _pointAt(angle, (geometry.innerR + geometry.outerR) / 2);
      final selected = isSelected(numbers[i]);
      final painter = TextPainter(
        text: TextSpan(
          text: '${numbers[i]}',
          style: AppTextStyles.font12RegularHint.copyWith(
            fontSize: 11,
            color: selected ? Colors.white : AppColorsManger.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        point - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArchPainter oldDelegate) => true;
}

/// The shallow wavy line separating the upper and lower arches — where the
/// bite line would be.
class _ArchDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _WavePainter());
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.9,
        size.width * 0.5,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.1,
        size.width,
        size.height * 0.3,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColorsManger.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => false;
}

class _ToothChip extends StatelessWidget {
  const _ToothChip({required this.toothNumber, required this.onRemove});

  final int toothNumber;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColorsManger.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$toothNumber',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: AppColorsManger.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColorsManger.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tap target placed between two consecutive tooth chips to toggle whether
/// they're connected (a bridge span) or separate.
class _ConnectorToggle extends StatelessWidget {
  const _ConnectorToggle({required this.isConnected, required this.onTap});

  final bool isConnected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: isConnected ? 'متصلين — اضغط للفصل' : 'منفصلين — اضغط للوصل',
        child: Icon(
          isConnected ? Icons.link : Icons.link_off,
          size: 18,
          color: isConnected
              ? AppColorsManger.primary
              : AppColorsManger.textHint,
        ),
      ),
    );
  }
}
