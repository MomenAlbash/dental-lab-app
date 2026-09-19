import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_state.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/save_priority_duration_request_model.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/create_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/repos/restoration_types_repo.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/save_restoration_type_price_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/update_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_type_form/restoration_type_form_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_type_form/restoration_type_form_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/restoration_types/ui/widgets/restoration_type_form_fields.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add/edit restoration-type screen. Pass [initialRestorationType] to edit.
class RestorationTypeFormPage extends StatelessWidget {
  const RestorationTypeFormPage({super.key, this.initialRestorationType});

  final RestorationTypeModel? initialRestorationType;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<RestorationTypeFormCubit>()),
        // The durations are one row per level the lab declared, so the form
        // cannot draw them without the levels themselves.
        BlocProvider(
          create: (_) => getIt<CasePrioritiesCubit>()..getCasePriorities(),
        ),
      ],
      child: _RestorationTypeFormView(
        initialRestorationType: initialRestorationType,
      ),
    );
  }
}

class _RestorationTypeFormView extends StatefulWidget {
  const _RestorationTypeFormView({this.initialRestorationType});

  final RestorationTypeModel? initialRestorationType;

  @override
  State<_RestorationTypeFormView> createState() =>
      _RestorationTypeFormViewState();
}

class _RestorationTypeFormViewState extends State<_RestorationTypeFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialRestorationType?.name ?? '',
  );
  late final _nameArController = TextEditingController(
    text: widget.initialRestorationType?.nameAr ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.initialRestorationType?.description ?? '',
  );
  late final _transparencyController = TextEditingController(
    text: widget.initialRestorationType?.transparency?.toString() ?? '',
  );

  /// One controller per priority level the lab declared, built once the levels
  /// arrive. Keyed by the level so each row labels itself with the name the
  /// lab wrote — four fixed boxes were the retired CasePriority enum.
  final Map<CasePriorityModel, TextEditingController> _durationControllers = {};

  late int _pricingType = widget.initialRestorationType?.pricingType ?? 1;
  late bool _isActive = widget.initialRestorationType?.isActive ?? true;

  /// Seeded from the type's existing per-currency prices so an edit that
  /// never opens this section resends exactly what was already there.
  late final List<SaveRestorationTypePriceRequestModel> _prices = [
    for (final p in widget.initialRestorationType?.prices ?? const [])
      if (p.currencyId != null)
        SaveRestorationTypePriceRequestModel(
          currencyId: p.currencyId!,
          price: p.price,
        ),
  ];

  List<CurrencyModel> _currencies = [];
  bool _loadingCurrencies = true;

  bool get _isEditing => widget.initialRestorationType != null;

  /// Replaces the picture the **doctor-facing website** shows for this type.
  ///
  /// Its own action rather than a field in the form, because it is its own
  /// request: it uploads immediately and does not wait for save, so a user who
  /// picks a photo and then backs out still changed the photo. Offered only
  /// while editing — there is no id to attach it to before the type exists.
  Future<void> _changeWebsiteImage() async {
    final id = widget.initialRestorationType?.id;
    if (id == null) return;

    final result = await FilePicker.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;

    final uploaded = await getIt<RestorationTypesRepo>().uploadWebsiteImage(
      id: id,
      filePath: path,
    );
    if (!mounted) return;

    uploaded.fold(
      (failure) =>
          showToast(message: failure.errorMessage, state: ToastState.error),
      (_) => showToast(
        message: 'تم تحديث صورة الموقع',
        state: ToastState.success,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
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

  Future<void> _addPrice() async {
    final alreadyPriced = _prices.map((p) => p.currencyId).toSet();
    final choices = _currencies
        .where((c) => !alreadyPriced.contains(c.id))
        .toList();

    if (choices.isEmpty) {
      showToast(
        message: 'كل العملات المتوفرة عندها سعر مسبقاً',
        state: ToastState.error,
      );
      return;
    }

    final price = await showDialog<SaveRestorationTypePriceRequestModel>(
      context: context,
      builder: (_) => _CurrencyPriceFormDialog(currencies: choices),
    );
    if (price == null) return;

    setState(() => _prices.add(price));
  }

  void _removePrice(int index) => setState(() => _prices.removeAt(index));

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _transparencyController.dispose();
    for (final controller in _durationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  double? _optionalDouble(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : double.tryParse(value);
  }

  /// Only the levels the user actually filled in. An empty box means "not
  /// estimated yet" — sending it as zero would claim the work is instant.
  /// The box holds a plain minute total; the model splits it into the
  /// days-plus-remainder shape the API actually stores.
  List<SavePriorityDurationRequestModel> get _durations => [
    for (final entry in _durationControllers.entries)
      if (int.tryParse(entry.value.text.trim()) case final minutes?)
        SavePriorityDurationRequestModel.fromTotalMinutes(
          casePriorityId: entry.key.id,
          totalMinutes: minutes,
        ),
  ];

  /// Builds a row per priority the moment the levels arrive, prefilled from
  /// whatever this type already has for each.
  void _syncDurationControllers(List<CasePriorityModel> priorities) {
    final existing = {
      for (final duration
          in widget.initialRestorationType?.durations ?? const [])
        duration.casePriorityId: duration.durationMinutes,
    };

    for (final priority in priorities) {
      _durationControllers.putIfAbsent(
        priority,
        () => TextEditingController(
          text: existing[priority.id]?.toString() ?? '',
        ),
      );
    }
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Not a form-field validator: the price rows live outside the `Form`
    // widget's own fields, so the server's own rule — at least one price —
    // is checked here instead of silently letting a 400 explain it.
    if (_prices.isEmpty) {
      showToast(
        message: 'أضف سعراً واحداً على الأقل قبل الحفظ',
        state: ToastState.error,
      );
      return;
    }

    final cubit = context.read<RestorationTypeFormCubit>();

    if (_isEditing) {
      cubit.updateRestorationType(
        id: widget.initialRestorationType!.id,
        updateRequestBody: UpdateRestorationTypeRequestModel(
          name: _nameController.text.trim(),
          nameAr: _optional(_nameArController),
          description: _optional(_descriptionController),
          transparency: _optionalDouble(_transparencyController),
          prices: _prices,
          pricingType: _pricingType,
          isActive: _isActive,
          durations: _durations,
        ),
      );
    } else {
      cubit.createRestorationType(
        CreateRestorationTypeRequestModel(
          name: _nameController.text.trim(),
          nameAr: _optional(_nameArController),
          description: _optional(_descriptionController),
          transparency: _optionalDouble(_transparencyController),
          prices: _prices,
          pricingType: _pricingType,
          durations: _durations,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilt as the levels arrive: the form paints before the request lands,
    // so the rows have to appear when it does rather than staying empty until
    // the user reopens the screen.
    final prioritiesState = context.watch<CasePrioritiesCubit>().state;
    if (prioritiesState is CasePrioritiesLoaded) {
      _syncDurationControllers(prioritiesState.priorities);
    }

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          _isEditing ? 'تعديل التعويض' : 'إضافة تعويض',
          style: AppTextStyles.font18MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'صورة الموقع',
              onPressed: _changeWebsiteImage,
              icon: const Icon(Icons.image_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<RestorationTypeFormCubit, RestorationTypeFormState>(
          listener: (context, state) {
            switch (state) {
              case RestorationTypeFormSuccess():
                showToast(
                  message: _isEditing
                      ? 'تم حفظ التعديلات'
                      : 'تمت إضافة التعويض',
                  state: ToastState.success,
                );
                Navigator.of(context).pop(true);
              case RestorationTypeFormError(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                final contentWidth = isWide ? 560.0 : constraints.maxWidth;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 32 : 20,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: RestorationTypeFormFields(
                        formKey: _formKey,
                        nameController: _nameController,
                        nameArController: _nameArController,
                        descriptionController: _descriptionController,
                        transparencyController: _transparencyController,
                        durationControllers: _durationControllers,
                        pricingType: _pricingType,
                        onPricingTypeChanged: (value) =>
                            setState(() => _pricingType = value),
                        currencies: _currencies,
                        loadingCurrencies: _loadingCurrencies,
                        prices: _prices,
                        onAddPrice: _addPrice,
                        onRemovePrice: _removePrice,
                        isEditing: _isEditing,
                        isActive: _isActive,
                        onActiveChanged: (value) =>
                            setState(() => _isActive = value),
                        isSubmitting: state is RestorationTypeFormSubmitting,
                        onSave: _onSavePressed,
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

/// Asks for a stage name. Owns its controller so it isn't disposed while the
/// dialog is still animating out.
class _AddStageDialog extends StatefulWidget {
  const _AddStageDialog();

  @override
  State<_AddStageDialog> createState() => _AddStageDialogState();
}

class _AddStageDialogState extends State<_AddStageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onAdd() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة مرحلة', style: AppTextStyles.font18MediumText),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: AppTextFormField(
            controller: _nameController,
            hintText: 'اسم المرحلة (مثال: التصميم)',
            prefixIcon: Icon(
              Icons.timeline_outlined,
              color: context.glass.onGlassMuted,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'اسم المرحلة مطلوب'
                : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _onAdd, child: const Text('إضافة')),
      ],
    );
  }
}

/// Picks one currency (from those this type is not already priced in) and a
/// price for it.
class _CurrencyPriceFormDialog extends StatefulWidget {
  const _CurrencyPriceFormDialog({required this.currencies});

  final List<CurrencyModel> currencies;

  @override
  State<_CurrencyPriceFormDialog> createState() =>
      _CurrencyPriceFormDialogState();
}

class _CurrencyPriceFormDialogState extends State<_CurrencyPriceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  String? _currencyId;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final currencyId = _currencyId;
    if (currencyId == null) {
      showToast(message: 'اختر العملة', state: ToastState.error);
      return;
    }

    Navigator.of(context).pop(
      SaveRestorationTypePriceRequestModel(
        currencyId: currencyId,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة سعر لعملة', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CaseLookupDropdown(
                  value: _currencyId,
                  icon: Icons.currency_exchange_outlined,
                  hintText: 'اختر العملة',
                  items: widget.currencies
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name ?? c.code ?? '—'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _currencyId = value),
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _priceController,
                  hintText: 'السعر',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icon(
                    Icons.attach_money_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) {
                    final price = double.tryParse(value?.trim() ?? '');
                    if (price == null || price < 0) return 'أدخل سعراً صحيحاً';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _onConfirm, child: const Text('إضافة')),
      ],
    );
  }
}
