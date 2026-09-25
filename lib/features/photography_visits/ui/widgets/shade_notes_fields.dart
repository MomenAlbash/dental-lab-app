import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';
import 'package:flutter/material.dart';

/// The text controllers behind [ShadeNotesFields], owned by the screen's
/// State so they are created once and disposed with it — never in build().
class ShadeNotesControllers {
  ShadeNotesControllers([
    PhotographyShadeNotes initial = const PhotographyShadeNotes(),
  ]) : toothShade = TextEditingController(text: initial.toothShade ?? ''),
       translucency = TextEditingController(
         text: initial.translucencyNotes ?? '',
       ),
       gradientAndShape = TextEditingController(
         text: initial.gradientAndShapeNotes ?? '',
       ),
       smileLine = TextEditingController(text: initial.smileLineNotes ?? ''),
       gumColor = TextEditingController(text: initial.gumColorNotes ?? ''),
       shadeGuideUsed = ValueNotifier(initial.shadeGuideUsed);

  final TextEditingController toothShade;
  final TextEditingController translucency;
  final TextEditingController gradientAndShape;
  final TextEditingController smileLine;
  final TextEditingController gumColor;
  final ValueNotifier<bool> shadeGuideUsed;

  static String? _text(TextEditingController c) {
    final value = c.text.trim();
    return value.isEmpty ? null : value;
  }

  PhotographyShadeNotes toModel() => PhotographyShadeNotes(
    toothShade: _text(toothShade),
    shadeGuideUsed: shadeGuideUsed.value,
    translucencyNotes: _text(translucency),
    gradientAndShapeNotes: _text(gradientAndShape),
    smileLineNotes: _text(smileLine),
    gumColorNotes: _text(gumColor),
  );

  void dispose() {
    toothShade.dispose();
    translucency.dispose();
    gradientAndShape.dispose();
    smileLine.dispose();
    gumColor.dispose();
    shadeGuideUsed.dispose();
  }
}

/// Tooth shade and the clinical notes a photography visit captures.
class ShadeNotesFields extends StatelessWidget {
  const ShadeNotesFields({
    super.key,
    required this.controllers,
    this.enabled = true,
  });

  final ShadeNotesControllers controllers;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Widget field(TextEditingController controller, String hint) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppTextFormField(
        controller: controller,
        hintText: hint,
        enabled: enabled,
        maxLines: controller == controllers.toothShade ? 1 : 2,
        validator: (_) => null,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field(controllers.toothShade, 'لون السن (الشيد)'),
        ValueListenableBuilder<bool>(
          valueListenable: controllers.shadeGuideUsed,
          builder: (context, used, _) => SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('استُخدم دليل الألوان'),
            value: used,
            onChanged: enabled
                ? (v) => controllers.shadeGuideUsed.value = v
                : null,
          ),
        ),
        field(controllers.translucency, 'ملاحظات الشفافية'),
        field(controllers.gradientAndShape, 'التدرّج والشكل'),
        field(controllers.smileLine, 'خط الابتسامة'),
        field(controllers.gumColor, 'لون اللثة'),
      ],
    );
  }
}
