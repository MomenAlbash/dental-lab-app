import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a stage form offers only the two real intakes', () {
    // The API declares this enum as {2, 3}; "both" was retired, and a stage
    // that belongs to both pipelines is two rows now. Offering the old value
    // would build a request the server refuses.
    expect(RouteStageAppliesTo.selectable, [
      RouteStageAppliesTo.traditionalOnly,
      RouteStageAppliesTo.digitalOnly,
    ]);
    expect(
      RouteStageAppliesTo.selectable.contains(RouteStageAppliesTo.any),
      isFalse,
    );
  });

  test('the retired value still parses, so an old stage stays visible', () {
    // Dropping it from the enum would hide a stage the lab can still see on
    // the server — worse than showing one that needs re-saving.
    expect(RouteStageAppliesTo.fromValue(1), RouteStageAppliesTo.any);
    expect(
      RouteStageAppliesTo.fromValue(2),
      RouteStageAppliesTo.traditionalOnly,
    );
    expect(RouteStageAppliesTo.fromValue(3), RouteStageAppliesTo.digitalOnly);
  });
}
