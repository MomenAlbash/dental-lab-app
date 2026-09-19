import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_currency_price_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/data/models/shade_codes.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';
import 'package:dental_lab_app/features/cases/logic/route_preview/route_preview_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/case_form_page.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/restoration_route_section.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/shade_guide.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/tooth_chart_widget.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/tooth_shade_diagram.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether the signed-in user may see and set restoration prices.
///
/// Pricing is the administrator's business, not the technician's: a case is
/// filed by whoever takes it in, and what the laboratory charges is not theirs
/// to set — nor to have on screen while a doctor is standing beside them.
bool get _canSeePrices => getIt<SessionCubit>().state.isAdmin;

/// Step — the restoration lines for the case. Each restoration owns its own
/// teeth (with bridge connections), added through [AddRestorationPage].
class CaseRestorationsStep extends StatelessWidget {
  const CaseRestorationsStep({
    super.key,
    required this.restorations,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final List<RestorationEntry> restorations;
  final VoidCallback onAdd;

  /// Reopens a line for correction. Without it a typo in the shade or the
  /// tooth chart costs the whole entry.
  final ValueChanged<int> onEdit;

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
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: context.glass.onGlassMuted,
              ),
            ),
          )
        else
          ...restorations.asMap().entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: context.glass.surfaceGradient,
                borderRadius: BorderRadius.circular(AppRadius.glass),
                border: Border.all(color: context.glass.strokeColor),
                boxShadow: context.glass.shadows,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: context.glass.brandGradient,
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value.restorationName,
                          style: AppTextStyles.font14MediumText.copyWith(
                            color: context.glass.onGlass,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'عدد القطع: ${entry.value.quantity}'
                          '${_canSeePrices && entry.value.unitPrice != null ? ' • ${entry.value.unitPrice!.toStringAsFixed(0)} ${entry.value.currencyName ?? ''}' : ''}'
                          '${entry.value.teeth.isNotEmpty ? ' • الأسنان: ${entry.value.teeth.map((t) => t.toothNumber).join(', ')}' : ''}',
                          style: AppTextStyles.font12RegularHint.copyWith(
                            color: context.glass.onGlassMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'تعديل',
                    onPressed: () => onEdit(entry.key),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: context.glass.onGlassMuted,
                    ),
                  ),
                  IconButton(
                    tooltip: 'حذف',
                    onPressed: () => onRemove(entry.key),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close, color: context.glass.error),
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
        child: Text(
          text,
          style: AppTextStyles.font14MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
      ),
    );
  }
}

/// Fullscreen "add restoration" flow: restoration type, quantity, price,
/// notes, and the affected teeth (with bridge connections) via
/// [ToothChartWidget]. Requires a [RestorationTypesCubit] in the tree
/// (provided by the caller).
class AddRestorationPage extends StatefulWidget {
  const AddRestorationPage({
    super.key,
    this.impressionMethod,
    this.priorityId,
    this.initial,
    this.takenTeeth = const {},
  });

  /// The case's intake, passed down so the route preview prunes the same
  /// stages the server will.
  final ImpressionMethod? impressionMethod;

  /// Priorities carry per-type durations, so the preview's expected time
  /// depends on which one the case is filed under.
  final String? priorityId;

  /// The line being corrected. Null adds a new one.
  ///
  /// Editing exists because a restoration is the most expensive thing on this
  /// form to enter — a type, a shade, and a tooth chart — and a typo in it used
  /// to mean deleting the line and building it again from nothing.
  final RestorationEntry? initial;

  /// Teeth the case's other restorations already claim. They show on the chart
  /// as spoken for and cannot be picked again — a tooth carries one
  /// restoration, and marking it twice files a case whose piece counts do not
  /// match the mouth.
  final Set<int> takenTeeth;

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

  /// The lab's own currencies — the fallback currency picker for a type with
  /// no per-currency prices of its own (a single-currency lab, or a type
  /// nobody has priced yet).
  List<CurrencyModel> _currencies = [];
  bool _loadingCurrencies = true;
  String? _currencyId;

  /// The selected type's own per-currency prices. Non-empty means the price
  /// is resolved from here once a currency is picked, not typed by hand —
  /// picking any other currency has no price behind it and the server
  /// refuses the case.
  List<RestorationCurrencyPriceModel> _typePrices = [];

  bool get _priceIsFromType => _typePrices.isNotEmpty;

  ShadeGuide _guide = ShadeGuide.vitaClassical;
  String? _shadeCervical;
  String? _shadeMiddle;
  String? _shadeIncisal;
  String? _baseToothColor;

  /// "عام" (one colour for the whole tooth) vs "مخصص" (a separate one per
  /// clinical zone). Client-side only — the API has no field for it, so this
  /// only decides which picker is shown; a uniform pick still writes all
  /// three zones the same, and a custom edit that happens to leave them equal
  /// still reads back as uniform the next time the line is opened.
  bool _uniformShade = true;

  /// Sets all three zones to the same shade — what picking a colour in
  /// "عام" mode means, since the request has no field of its own for it.
  void _setUniformShade(String? value) {
    setState(() {
      _shadeCervical = value;
      _shadeMiddle = value;
      _shadeIncisal = value;
    });
  }

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();

    if (_canSeePrices) _loadCurrencies();

    final initial = widget.initial;
    if (initial == null) {
      // A shade is expected on every line in practice, so a new one opens
      // pre-filled with the guide's own first shade rather than blank —
      // "عام" is a single tap to confirm instead of three to fill in.
      final defaultShade = _guide.shades.first;
      _shadeCervical = defaultShade;
      _shadeMiddle = defaultShade;
      _shadeIncisal = defaultShade;
      return;
    }

    _typeId = initial.restorationTypeId;
    _typeName = initial.restorationName;
    _teeth = [...initial.teeth];
    _quantityController.text = '${initial.quantity}';
    _priceController.text = initial.unitPrice?.toString() ?? '';
    _currencyId = initial.currencyId;
    final typesState = context.read<RestorationTypesCubit>().state;
    if (typesState is RestorationTypesLoaded) {
      _typePrices =
          typesState.types
              .where((t) => t.id == initial.restorationTypeId)
              .firstOrNull
              ?.prices ??
          const [];
    }
    _notesController.text = initial.notes ?? '';
    _shadeCervical = initial.shadeCervical;
    _shadeMiddle = initial.shadeMiddle;
    _shadeIncisal = initial.shadeIncisal;
    _baseToothColor = initial.baseToothColor;
    _guide = ShadeGuide.values.firstWhere(
      (guide) => guide.label == initial.shadeLayout,
      orElse: () => ShadeGuide.vitaClassical,
    );
    // Reopening a line the three zones were saved equal on (including a line
    // saved before "عام"/"مخصص" existed, where they are usually all null)
    // should still show as "عام" — the split is only real once the zones
    // actually disagree.
    _uniformShade =
        _shadeCervical == _shadeMiddle && _shadeMiddle == _shadeIncisal;

    // The route section otherwise never loads on an edit — nothing else
    // triggers it until the user reopens the type dropdown, so reopening a
    // line to fix a typo showed no route at all.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RoutePreviewCubit>().load(
        restorationTypeId: initial.restorationTypeId,
        impressionMethod: widget.impressionMethod,
      );
    });
  }

  Future<void> _loadCurrencies() async {
    final result = await getIt<AccountingRepo>().getCurrencies();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loadingCurrencies = false),
      (currencies) => setState(() {
        _currencies = currencies;
        _loadingCurrencies = false;
      }),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// The piece count has to match the teeth marked on the chart.
  ///
  /// They are two statements of the same fact — "three units" and three marked
  /// teeth — and a case where they disagree is one the laboratory has to stop
  /// and ring the clinic about. Checked here rather than left to the server so
  /// it is caught while the chart is still on screen.
  ///
  /// Only enforced once teeth are marked: a line entered before the chart is
  /// filled in is incomplete, not wrong, and blocking it would stop the user
  /// halfway through their own order of work.
  String? _validateQuantity(String? value) {
    final quantity = int.tryParse(value?.trim() ?? '');
    if (quantity == null) return 'عدد القطع مطلوب';
    if (quantity < 1) return 'عدد القطع لا يقل عن 1';

    if (_teeth.isNotEmpty && quantity != _teeth.length) {
      return 'عدد القطع ($quantity) لا يطابق الأسنان المحددة (${_teeth.length})';
    }
    return null;
  }

  String? get _selectedCurrencyLabel {
    if (_priceIsFromType) {
      for (final price in _typePrices) {
        if (price.currencyId == _currencyId) return price.currencyLabel;
      }
      return null;
    }
    for (final currency in _currencies) {
      if (currency.id == _currencyId) {
        return currency.code ?? currency.name ?? currency.symbol;
      }
    }
    return null;
  }

  void _onAdd() {
    // The fields are validated before the type is checked, so every problem
    // paints at once. The other order meant fixing the type, tapping again,
    // and only then being told the piece count was wrong too.
    final fieldsValid = _formKey.currentState?.validate() ?? false;

    if (_typeId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء اختيار التعويض')));
      return;
    }

    if (!fieldsValid) return;

    Navigator.of(context).pop(
      RestorationEntry(
        restorationTypeId: _typeId!,
        restorationName: _typeName ?? '—',
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        unitPrice: _priceController.text.trim().isEmpty
            ? null
            : double.tryParse(_priceController.text.trim()),
        currencyId: _currencyId,
        currencyName: _selectedCurrencyLabel,
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
      backgroundColor: Colors.transparent,
      child: GlassScaffold(
        appBar: GlassAppBar(
          title: Text(
            _isEditing ? 'تعديل التعويض' : 'إضافة تعويض',
            style: AppTextStyles.font18MediumText.copyWith(
              color: context.glass.onGlass,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          actions: [
            TextButton(
              onPressed: _onAdd,
              child: Text(_isEditing ? 'حفظ التعديل' : 'إضافة'),
            ),
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
                        onChanged: (value) {
                          final selected = types
                              ?.where((t) => t.id == value)
                              .firstOrNull;
                          setState(() {
                            _typeId = value;
                            _typeName = selected?.displayName;
                            // The price list belongs to the type, so a
                            // currency/price picked for another type means
                            // nothing here — same reason the route reloads.
                            _typePrices = selected?.prices ?? const [];
                            _currencyId = null;
                            _priceController.clear();
                          });
                          // The route options belong to the type too, and are
                          // reloaded from scratch for the same reason.
                          if (value != null) {
                            context.read<RoutePreviewCubit>().load(
                              restorationTypeId: value,
                              impressionMethod: widget.impressionMethod,
                            );
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const _FieldLabel('عدد القطع'),
                  AppTextFormField(
                    controller: _quantityController,
                    hintText: _teeth.isEmpty
                        ? 'أدخل عدد القطع'
                        : 'يجب أن يساوي عدد الأسنان المحددة (${_teeth.length})',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icon(
                      Icons.numbers_outlined,
                      color: context.glass.onGlassMuted,
                    ),
                    validator: _validateQuantity,
                  ),
                  // Pricing is the administrator's business, not the
                  // technician's: a case is filed by whoever takes it in, and
                  // what the laboratory charges for it is not theirs to set or
                  // to read off the screen while a doctor stands beside them.
                  if (_canSeePrices) ...[
                    const SizedBox(height: 12),
                    const _FieldLabel('العملة'),
                    CaseLookupDropdown(
                      value: _currencyId,
                      icon: Icons.currency_exchange_outlined,
                      hintText: _priceIsFromType
                          ? 'اختر العملة'
                          : _loadingCurrencies
                          ? 'جارٍ تحميل العملات...'
                          : 'اختر العملة (اختياري)',
                      items: _priceIsFromType
                          ? _typePrices
                                .where((p) => p.currencyId != null)
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.currencyId,
                                    child: Text(p.currencyLabel),
                                  ),
                                )
                                .toList()
                          : _currencies
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name ?? c.code ?? '—'),
                                  ),
                                )
                                .toList(),
                      onChanged: (value) => setState(() {
                        _currencyId = value;
                        // The price belongs to the (type, currency) pair —
                        // typing one over it would quote a number the server
                        // has no matching row for and refuses.
                        if (_priceIsFromType) {
                          final match = _typePrices
                              .where((p) => p.currencyId == value)
                              .firstOrNull;
                          _priceController.text = match?.price.toString() ?? '';
                        }
                      }),
                    ),
                    const SizedBox(height: 12),
                    const _FieldLabel('سعر الوحدة'),
                    AppTextFormField(
                      controller: _priceController,
                      enabled: !_priceIsFromType,
                      hintText: _priceIsFromType
                          ? 'يُحدَّد تلقائياً حسب العملة'
                          : 'أدخل سعر الوحدة',
                      prefixIcon: Icon(
                        Icons.attach_money_outlined,
                        color: context.glass.onGlassMuted,
                      ),
                      validator: (v) {
                        if (_priceIsFromType) {
                          return _currencyId == null ? 'اختر العملة' : null;
                        }
                        final trimmed = v?.trim() ?? '';
                        if (trimmed.isEmpty) return 'سعر الوحدة مطلوب';
                        final price = double.tryParse(trimmed);
                        if (price == null) return 'رقم غير صالح';
                        if (price < 0) return 'رقم غير صالح';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  const _FieldLabel('ملاحظات'),
                  AppTextFormField(
                    controller: _notesController,
                    hintText: 'أدخل ملاحظات (اختياري)',
                    prefixIcon: Icon(
                      Icons.notes_outlined,
                      color: context.glass.onGlassMuted,
                    ),
                    validator: (_) => null,
                  ),
                  // The lab's gating options and what they do to the route.
                  // Placed after the type and quantity, before the cosmetic
                  // shade choices: it changes what the lab will actually do.
                  const RestorationRouteSection(),
                  const SizedBox(height: 20),
                  const _FieldLabel('نوع التقسيمات'),
                  SegmentedButton<ShadeGuide>(
                    segments: ShadeGuide.values
                        .map(
                          (g) => ButtonSegment(value: g, label: Text(g.label)),
                        )
                        .toList(),
                    selected: {_guide},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _guide = s.first),
                  ),
                  const SizedBox(height: 16),
                  // "عام" (one colour for the whole tooth) is the common
                  // case and the default; "مخصص" is there for the tooth that
                  // actually needs the cervical/middle/incisal split named.
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('عام')),
                      ButtonSegment(value: false, label: Text('مخصص')),
                    ],
                    selected: {_uniformShade},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) {
                      final uniform = s.first;
                      if (uniform) {
                        // Collapsing three zones into one needs a single
                        // answer; the cervical zone's is as good as any.
                        _setUniformShade(_shadeCervical);
                      }
                      setState(() => _uniformShade = uniform);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_uniformShade)
                    UniformToothShade(
                      guide: _guide,
                      value: _shadeCervical,
                      onChanged: _setUniformShade,
                    )
                  else
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
                    // Always the fixed BaseShade list, independent of the
                    // layered-shade guide above: the API's base color enum
                    // has no Vita 3D-Master variant, so offering those codes
                    // here produced a value the server could never accept.
                    items: ShadeCodes.baseShadeLabels
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _baseToothColor = v),
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('الأسنان'),
                  ToothChartWidget(
                    teeth: _teeth,
                    takenTeeth: widget.takenTeeth,
                    onChanged: (teeth) {
                      setState(() => _teeth = teeth);
                      // Re-run the piece-count check against the new chart.
                      // Without this the mismatch only surfaces on submit,
                      // long after the user has moved on from the field.
                      _formKey.currentState?.validate();
                    },
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
