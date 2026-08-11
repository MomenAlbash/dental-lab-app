import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:flutter/material.dart';

/// The body of a detail screen, under its hero header.
///
/// A detail screen is a stack of sections — info tiles, attachments, quick
/// actions, a decision panel. On a phone there is only one place to put them:
/// one under the other. On a tablet that same column, capped at ~640dp and
/// centred, wastes half the screen and pushes the sections the user came for
/// below the fold; the width is there, so the sections use it.
///
/// Sections are split by role rather than by order:
///
/// * [main] — what the screen is about (the information, the attachments).
///   Gets the wider column.
/// * [side] — what the user can do about it (actions, pending decisions).
///   Gets the narrower one.
///
/// On a phone [side] comes first, because an action or a decision waiting on
/// the user is the thing to deal with before reading anything.
class AdaptiveDetailSections extends StatelessWidget {
  const AdaptiveDetailSections({
    super.key,
    required this.main,
    this.side = const [],
    this.gap = AppSpacing.xl,
  });

  final List<Widget> main;
  final List<Widget> side;

  /// Vertical space between sections, and horizontal space between columns.
  final double gap;

  /// Kept to a readable measure on a phone. Body text past this gets hard to
  /// track from one line to the next.
  static const double _phoneMaxWidth = 640;

  /// The two columns are 3:2 rather than even — the side column holds buttons
  /// and short panels, and an even split leaves it half empty while squeezing
  /// the information beside it.
  static const int _mainFlex = 3;
  static const int _sideFlex = 2;

  List<Widget> _spaced(List<Widget> sections) {
    return [
      for (var i = 0; i < sections.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        sections[i],
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout.tabletUp(
      mobileLayout: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _phoneMaxWidth),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screen,
              gap,
              AppSpacing.screen,
              gap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _spaced([...side, ...main]),
            ),
          ),
        ),
      ),
      tabletLayout: (context) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.xl, gap, AppSpacing.xl, gap),
        child: Row(
          // The columns are different lengths and each starts at the top;
          // stretching them to match would leave one full of empty space.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: _mainFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _spaced(main),
              ),
            ),
            // With nothing to put beside it, the information keeps the whole
            // width instead of a blank column being reserved for it.
            if (side.isNotEmpty) ...[
              SizedBox(width: gap),
              Expanded(
                flex: _sideFlex,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _spaced(side),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
