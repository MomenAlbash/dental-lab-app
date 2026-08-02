import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';
import 'package:dental_lab_app/features/cases/ui/case_form_page.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/shade_guide.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/tooth_chart_widget.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/tooth_shade_diagram.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step — the restoration lines for the case. Each restoration owns its own
/// teeth (with bridge connections), added through [AddRestorationPage].
class CaseRestorationsStep extends StatelessWidget {
  const CaseRestorationsStep({
    super.key,
    required this.restorations,
    required this.onAdd,
    required this.onRemove,
  });

  final List<RestorationEntry> restorations;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('إضافة تعويض'),
        ),
        const SizedBox(height: 12),
        if (restorations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'لم تتم إضافة تعويضات',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary,
            ),
          )
        else
          ...restorations.asMap().entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColorsManger.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColorsManger.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.category_outlined,
                    color: AppColorsManger.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value.restorationName,
                          style: AppTextStyles.font14MediumText,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'الكمية: ${entry.value.quantity}'
                          '${entry.value.unitPrice != null ? ' • ${entry.value.unitPrice!.toStringAsFixed(0)}' : ''}'
                          '${entry.value.teeth.isNotEmpty ? ' • الأسنان: ${entry.value.teeth.map((t) => t.toothNumber).join(', ')}' : ''}',
                          style: AppTextStyles.font12RegularHint,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemove(entry.key),
                    icon: const Icon(
                      Icons.close,
                      color: AppColorsManger.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, style: AppTextStyles.font14MediumText),
      ),
    );
  }
}

/// Fullscreen "add restoration" flow: restoration type, quantity, price,
/// notes, and the affected teeth (with bridge connections) via
/// [ToothChartWidget]. Requires a [RestorationTypesCubit] in the tree
/// (provided by the caller).
class AddRestorationPage extends StatefulWidget {
  const AddRestorationPage({super.key});

  @override
  State<AddRestorationPage> createState() => _AddRestorationPageState();
}

class _AddRestorationPageState extends State<AddRestorationPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _typeId;
  String? _typeName;
  List<ToothMarkModel> _teeth = [];

  ShadeGuide _guide = ShadeGuide.vitaClassical;
  String? _shadeCervical;
  String? _shadeMiddle;
  String? _shadeIncisal;
  String? _baseToothColor;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAdd() {
    if (_typeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار التعويض')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      RestorationEntry(
        restorationTypeId: _typeId!,
        restorationName: _typeName ?? '—',
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        unitPrice: _priceController.text.trim().isEmpty
            ? null
            : double.tryParse(_priceController.text.trim()),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        teeth: _teeth,
        shadeLayout: _guide.label,
        shadeCervical: _shadeCervical,
        shadeMiddle: _shadeMiddle,
        shadeIncisal: _shadeIncisal,
        baseToothColor: _baseToothColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: AppColorsManger.background,
        appBar: AppBar(
          title: Text('إضافة تعويض', style: AppTextStyles.font18MediumText),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          actions: [
            TextButton(onPressed: _onAdd, child: const Text('إضافة')),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _FieldLabel('التعويض'),
                  BlocBuilder<RestorationTypesCubit, RestorationTypesState>(
                    builder: (context, state) {
                      final types = state is RestorationTypesLoaded
                          ? state.types
                          : null;
                      return CaseLookupDropdown(
                        value: _typeId,
                        icon: Icons.category_outlined,
                        hintText: state is RestorationTypesLoading
                            ? 'جارٍ تحميل التعويضات...'
                            : 'اختر التعويض',
                        items: types
                            ?.map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          _typeId = value;
                          _typeName = types
                              ?.firstWhere((t) => t.id == value)
                              .displayName;
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel('الكمية'),
                  AppTextFormField(
                    controller: _quantityController,
                    hintText: 'أدخل الكمية',
                    prefixIcon: const Icon(
                      Icons.numbers_outlined,
                      color: AppColorsManger.textSecondary,
                    ),
                    validator: (v) =>
                        (v == null || int.tryParse(v.trim()) == null)
                        ? 'الكمية مطلوبة'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel('سعر الوحدة'),
                  AppTextFormField(
                    controller: _priceController,
                    hintText: 'أدخل سعر الوحدة (اختياري)',
                    prefixIcon: const Icon(
                      Icons.attach_money_outlined,
                      color: AppColorsManger.textSecondary,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      return double.tryParse(v) == null ? 'رقم غير صالح' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel('ملاحظات'),
                  AppTextFormField(
                    controller: _notesController,
                    hintText: 'أدخل ملاحظات (اختياري)',
                    prefixIcon: const Icon(
                      Icons.notes_outlined,
                      color: AppColorsManger.textSecondary,
                    ),
                    validator: (_) => null,
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('نوع التقسيمات'),
                  SegmentedButton<ShadeGuide>(
                    segments: ShadeGuide.values
                        .map((g) => ButtonSegment(value: g, label: Text(g.label)))
                        .toList(),
                    selected: {_guide},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) =>
                        setState(() => _guide = s.first),
                  ),
                  const SizedBox(height: 16),
                  ToothShadeDiagram(
                    guide: _guide,
                    cervical: _shadeCervical,
                    middle: _shadeMiddle,
                    incisal: _shadeIncisal,
                    onCervicalChanged: (v) =>
                        setState(() => _shadeCervical = v),
                    onMiddleChanged: (v) => setState(() => _shadeMiddle = v),
                    onIncisalChanged: (v) =>
                        setState(() => _shadeIncisal = v),
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('لون أساس السن'),
                  CaseLookupDropdown(
                    value: _baseToothColor,
                    icon: Icons.palette_outlined,
                    hintText: 'لون أساس السن (اختياري)',
                    items: _guide.shades
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _baseToothColor = v),
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('الأسنان'),
                  ToothChartWidget(
                    teeth: _teeth,
                    onChanged: (teeth) => setState(() => _teeth = teeth),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
