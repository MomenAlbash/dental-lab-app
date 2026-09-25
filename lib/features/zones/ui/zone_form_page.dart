import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/areas/data/models/area_model.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/zones/data/models/save_zone_request_models.dart';
import 'package:dental_lab_app/features/zones/data/models/zone_model.dart';
import 'package:dental_lab_app/features/zones/logic/zone_form/zone_form_cubit.dart';
import 'package:dental_lab_app/features/zones/logic/zone_form/zone_form_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add/edit zone screen — picks the areas it covers and the employees who
/// work it as representatives.
class ZoneFormPage extends StatelessWidget {
  const ZoneFormPage({super.key, this.initialZone});

  final ZoneModel? initialZone;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ZoneFormCubit>()..loadCatalog(),
      child: _ZoneFormView(initialZone: initialZone),
    );
  }
}

class _ZoneFormView extends StatefulWidget {
  const _ZoneFormView({this.initialZone});

  final ZoneModel? initialZone;

  @override
  State<_ZoneFormView> createState() => _ZoneFormViewState();
}

class _ZoneFormViewState extends State<_ZoneFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialZone?.name ?? '',
  );
  late final _nameArController = TextEditingController(
    text: widget.initialZone?.nameAr ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.initialZone?.description ?? '',
  );
  late final _feeController = TextEditingController(
    text: widget.initialZone?.returnDeliveryFee?.toString() ?? '',
  );

  /// Shipping time, entered as days/hours/minutes and sent as one minute
  /// count — nobody thinks of "two days" as 2880.
  late final _initialShipping = ShippingDuration.fromMinutes(
    widget.initialZone?.shippingMinutes ?? 0,
  );
  late final _shippingDaysController = TextEditingController(
    text: '${_initialShipping.days}',
  );
  late final _shippingHoursController = TextEditingController(
    text: '${_initialShipping.hours}',
  );
  late final _shippingMinutesController = TextEditingController(
    text: '${_initialShipping.minutes}',
  );

  late String? _shippingCurrencyId = widget.initialZone?.shippingCurrencyId;

  late bool _isActive = widget.initialZone?.isActive ?? true;

  late final Set<String> _selectedAreaIds = {
    for (final a in widget.initialZone?.areas ?? const []) a.areaId,
  };
  late final Set<String> _selectedRepresentativeIds = {
    for (final r in widget.initialZone?.representatives ?? const []) r.userId,
  };

  bool get _isEditing => widget.initialZone != null;

  /// The catalog only ever arrives once; kept so a later Submitting/Success/
  /// Error state does not blank the checklist mid-save.
  List<AreaModel>? _lastAreas;
  List<UserModel>? _lastRepresentatives;
  List<CurrencyModel>? _lastCurrencies;

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _feeController.dispose();
    _shippingDaysController.dispose();
    _shippingHoursController.dispose();
    _shippingMinutesController.dispose();
    super.dispose();
  }

  int _count(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  ShippingDuration get _shipping => ShippingDuration(
    days: _count(_shippingDaysController),
    hours: _count(_shippingHoursController),
    minutes: _count(_shippingMinutesController),
  );

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_shipping.exceedsMax) return;

    final cubit = context.read<ZoneFormCubit>();
    final fee = _feeController.text.trim().isEmpty
        ? null
        : double.tryParse(_feeController.text.trim());
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    final nameAr = _nameArController.text.trim().isEmpty
        ? null
        : _nameArController.text.trim();

    if (_isEditing) {
      cubit.updateZone(
        id: widget.initialZone!.id,
        requestBody: UpdateZoneRequestModel(
          name: _nameController.text.trim(),
          nameAr: nameAr,
          description: description,
          isActive: _isActive,
          areaIds: _selectedAreaIds.toList(),
          representativeUserIds: _selectedRepresentativeIds.toList(),
          returnDeliveryFee: fee,
          shippingCurrencyId: _shippingCurrencyId,
          shippingMinutes: _shipping.totalMinutes,
          // An empty field on its own leaves the old fee in place; removing
          // it has to be asked for.
          clearReturnDeliveryFee:
              fee == null && widget.initialZone!.returnDeliveryFee != null,
        ),
      );
    } else {
      cubit.createZone(
        CreateZoneRequestModel(
          name: _nameController.text.trim(),
          nameAr: nameAr,
          description: description,
          isActive: _isActive,
          areaIds: _selectedAreaIds.toList(),
          representativeUserIds: _selectedRepresentativeIds.toList(),
          returnDeliveryFee: fee,
          shippingCurrencyId: _shippingCurrencyId,
          shippingMinutes: _shipping.totalMinutes,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          _isEditing ? 'تعديل المنطقة' : 'إضافة منطقة',
          style: AppTextStyles.font18MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<ZoneFormCubit, ZoneFormState>(
          listener: (context, state) {
            switch (state) {
              case ZoneFormSuccess(:final zone):
                showToast(
                  message: _isEditing
                      ? 'تم حفظ التعديلات'
                      : 'تمت إضافة المنطقة',
                  state: ToastState.success,
                );
                Navigator.of(context).pop(zone);
              case ZoneFormError(:final message):
                showToast(message: message, state: ToastState.error);
              case ZoneFormCatalogError(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          builder: (context, state) {
            final areas = switch (state) {
              ZoneFormCatalogLoaded(:final areas) => areas,
              ZoneFormSubmitting() ||
              ZoneFormSuccess() ||
              ZoneFormError() => _lastAreas,
              _ => null,
            };
            final representatives = switch (state) {
              ZoneFormCatalogLoaded(:final representatives) => representatives,
              ZoneFormSubmitting() ||
              ZoneFormSuccess() ||
              ZoneFormError() => _lastRepresentatives,
              _ => null,
            };
            final currencies = switch (state) {
              ZoneFormCatalogLoaded(:final currencies) => currencies,
              _ => _lastCurrencies,
            };
            if (areas != null) _lastAreas = areas;
            if (representatives != null) _lastRepresentatives = representatives;
            if (currencies != null) _lastCurrencies = currencies;
            // One currency means nothing to ask.
            if (_shippingCurrencyId == null && currencies?.length == 1) {
              _shippingCurrencyId = currencies!.single.id;
            }

            if (areas == null || representatives == null) {
              return state is ZoneFormCatalogError
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.font14RegularSecondary.copyWith(
                            color: context.glass.onGlassMuted,
                          ),
                        ),
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.all(24),
                      child: GlassListSkeleton(),
                    );
            }

            final isSubmitting = state is ZoneFormSubmitting;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    AdaptiveLayout.formFactorFor(constraints.maxWidth) !=
                    AdaptiveFormFactor.mobile;
                final contentWidth = isWide ? 560.0 : constraints.maxWidth;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 32 : 20,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'اسم المنطقة',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            AppTextFormField(
                              controller: _nameController,
                              hintText: 'أدخل اسم المنطقة',
                              textInputAction: TextInputAction.next,
                              enabled: !isSubmitting,
                              prefixIcon: Icon(
                                Icons.map_outlined,
                                color: context.glass.onGlassMuted,
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? 'اسم المنطقة مطلوب'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'الاسم بالعربي (اختياري)',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            AppTextFormField(
                              controller: _nameArController,
                              hintText: 'أدخل الاسم بالعربي',
                              textInputAction: TextInputAction.next,
                              enabled: !isSubmitting,
                              prefixIcon: Icon(
                                Icons.translate_outlined,
                                color: context.glass.onGlassMuted,
                              ),
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'الوصف (اختياري)',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            AppTextFormField(
                              controller: _descriptionController,
                              hintText: 'أدخل وصف المنطقة',
                              textInputAction: TextInputAction.next,
                              enabled: !isSubmitting,
                              prefixIcon: Icon(
                                Icons.notes_outlined,
                                color: context.glass.onGlassMuted,
                              ),
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 24),
                            const GlassSectionTitle('الشحن'),
                            _ShippingFields(
                              feeController: _feeController,
                              daysController: _shippingDaysController,
                              hoursController: _shippingHoursController,
                              minutesController: _shippingMinutesController,
                              currencies: currencies ?? const [],
                              currencyId: _shippingCurrencyId,
                              onCurrencyChanged: (id) =>
                                  setState(() => _shippingCurrencyId = id),
                              enabled: !isSubmitting,
                            ),
                            const SizedBox(height: 16),
                            _ActiveSwitch(
                              value: _isActive,
                              onChanged: isSubmitting
                                  ? null
                                  : (v) => setState(() => _isActive = v),
                            ),
                            const SizedBox(height: 24),
                            const GlassSectionTitle('الأحياء'),
                            const SizedBox(height: 4),
                            Text(
                              'اختر الأحياء التي تغطيها هذه المنطقة',
                              style: AppTextStyles.font12RegularHint.copyWith(
                                color: context.glass.onGlassMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (areas.isEmpty)
                              _EmptyCatalogNote(
                                message: 'لا يوجد أحياء بعد — أضفها أولاً',
                              )
                            else
                              for (final area in areas)
                                _CheckRow(
                                  label:
                                      '${area.name ?? '—'}'
                                      '${area.cityName != null ? ' (${area.cityName})' : ''}',
                                  value: _selectedAreaIds.contains(area.id),
                                  enabled: !isSubmitting,
                                  onChanged: (checked) => setState(() {
                                    if (checked) {
                                      _selectedAreaIds.add(area.id);
                                    } else {
                                      _selectedAreaIds.remove(area.id);
                                    }
                                  }),
                                ),
                            const SizedBox(height: 24),
                            const GlassSectionTitle('المندوبون'),
                            const SizedBox(height: 4),
                            Text(
                              'اختر المندوبين المسؤولين عن هذه المنطقة',
                              style: AppTextStyles.font12RegularHint.copyWith(
                                color: context.glass.onGlassMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (representatives.isEmpty)
                              _EmptyCatalogNote(
                                message:
                                    'لا يوجد مندوبون بعد — فعّل خيار "مندوب" '
                                    'عند إضافة موظف كمستخدم',
                              )
                            else
                              for (final rep in representatives)
                                _CheckRow(
                                  label: rep.linkedName.isEmpty
                                      ? (rep.username ?? '—')
                                      : rep.linkedName,
                                  // The zone stores representatives by their
                                  // own login id, not their employee record's
                                  // id — the two are different ids, and
                                  // sending the wrong one silently assigned
                                  // nobody.
                                  value: _selectedRepresentativeIds.contains(
                                    rep.id,
                                  ),
                                  enabled: !isSubmitting,
                                  onChanged: (checked) => setState(() {
                                    if (checked) {
                                      _selectedRepresentativeIds.add(rep.id);
                                    } else {
                                      _selectedRepresentativeIds.remove(rep.id);
                                    }
                                  }),
                                ),
                            const SizedBox(height: 24),
                            if (isSubmitting)
                              const Center(
                                child: CustomCircleProgressIndiacatorWidget(),
                              )
                            else
                              CustomButtonWidget(
                                onPressed: _onSavePressed,
                                buttonText: _isEditing
                                    ? 'حفظ التعديلات'
                                    : 'إضافة المنطقة',
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ActiveSwitch extends StatelessWidget {
  const _ActiveSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.glass.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.glass.strokeColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('مفعّلة', style: AppTextStyles.font14MediumText),
          ),
          Switch(
            value: value,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.font14MediumText)),
          Switch(
            value: value,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: enabled ? (v) => onChanged(v) : null,
          ),
        ],
      ),
    );
  }
}

class _EmptyCatalogNote extends StatelessWidget {
  const _EmptyCatalogNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: AppTextStyles.font12RegularHint.copyWith(
          color: context.glass.onGlassMuted,
        ),
      ),
    );
  }
}

/// The zone's delivery fee, its currency, and how long shipping takes —
/// with a live line saying what that adds to a case's delivery date.
class _ShippingFields extends StatelessWidget {
  const _ShippingFields({
    required this.feeController,
    required this.daysController,
    required this.hoursController,
    required this.minutesController,
    required this.currencies,
    required this.currencyId,
    required this.onCurrencyChanged,
    required this.enabled,
  });

  final TextEditingController feeController;
  final TextEditingController daysController;
  final TextEditingController hoursController;
  final TextEditingController minutesController;
  final List<CurrencyModel> currencies;
  final String? currencyId;
  final ValueChanged<String?> onCurrencyChanged;
  final bool enabled;

  static int _count(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  String? _validateCount(String? value, {int? max}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final count = int.tryParse(text);
    if (count == null || count < 0) return 'قيمة غير صالحة';
    if (max != null && count > max) return 'الحد $max';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('أجرة التوصيل (اختياري)', style: AppTextStyles.font14MediumText),
        const SizedBox(height: 8),
        AppTextFormField(
          controller: feeController,
          hintText: 'اتركها فارغة إن لم يكن التوصيل متاحاً',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: enabled,
          prefixIcon: Icon(
            Icons.local_shipping_outlined,
            color: glass.onGlassMuted,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final fee = double.tryParse(value.trim());
            return fee == null || fee < 0 ? 'قيمة غير صالحة' : null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: currencies.any((c) => c.id == currencyId)
              ? currencyId
              : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'العملة',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            for (final currency in currencies)
              DropdownMenuItem(
                value: currency.id,
                child: Text(currency.name ?? currency.code ?? '—'),
              ),
          ],
          onChanged: enabled ? onCurrencyChanged : null,
          validator: (value) =>
              // A fee with no currency is a number nobody can bill.
              feeController.text.trim().isNotEmpty && value == null
              ? 'اختر عملة الأجرة'
              : null,
        ),

        const SizedBox(height: 16),
        Text('مدة الشحن', style: AppTextStyles.font14MediumText),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextFormField(
                controller: daysController,
                hintText: 'أيام',
                keyboardType: TextInputType.number,
                enabled: enabled,
                validator: (value) => _validateCount(value, max: 365),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppTextFormField(
                controller: hoursController,
                hintText: 'ساعات',
                keyboardType: TextInputType.number,
                enabled: enabled,
                validator: (value) => _validateCount(value, max: 23),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppTextFormField(
                controller: minutesController,
                hintText: 'دقائق',
                keyboardType: TextInputType.number,
                enabled: enabled,
                validator: (value) => _validateCount(value, max: 59),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ListenableBuilder(
          listenable: Listenable.merge([
            daysController,
            hoursController,
            minutesController,
          ]),
          builder: (context, _) {
            final duration = ShippingDuration(
              days: _count(daysController),
              hours: _count(hoursController),
              minutes: _count(minutesController),
            );
            return Text(
              duration.exceedsMax
                  ? 'مدة الشحن لا يمكن أن تتجاوز سنة'
                  : duration.isZero
                  ? 'لا يضيف الشحن وقتاً على موعد التسليم'
                  : 'يضيف ${duration.label} على موعد التسليم',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: duration.exceedsMax ? glass.error : glass.onGlassMuted,
              ),
            );
          },
        ),
      ],
    );
  }
}
