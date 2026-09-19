import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/areas/data/models/area_model.dart';
import 'package:dental_lab_app/features/areas/data/models/save_area_request_models.dart';
import 'package:dental_lab_app/features/areas/logic/areas/areas_cubit.dart';
import 'package:dental_lab_app/features/areas/logic/areas/areas_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Districts ("أحياء") — plain CRUD scoped to a city (`/api/clinic/Areas`), a
/// zone picks its coverage from these.
class AreasListPage extends StatelessWidget {
  const AreasListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AreasCubit>()..getAreas()),
        BlocProvider(create: (_) => getIt<CitiesCubit>()..getCities()),
      ],
      child: const _AreasListView(),
    );
  }
}

class _AreasListView extends StatelessWidget {
  const _AreasListView();

  bool get _canEdit =>
      getIt<SessionCubit>().state.canEdit(PermissionName.users);

  Future<void> _openForm(BuildContext context, {AreaModel? area}) async {
    final areasCubit = context.read<AreasCubit>();
    final citiesCubit = context.read<CitiesCubit>();
    final result =
        await showDialog<({String name, String? nameAr, String? cityId})>(
          context: context,
          builder: (_) => BlocProvider.value(
            value: citiesCubit,
            child: _AreaFormDialog(initialArea: area),
          ),
        );
    if (result == null) return;

    if (area == null) {
      await areasCubit.addArea(
        CreateAreaRequestModel(
          cityId: result.cityId!,
          name: result.name,
          nameAr: result.nameAr,
        ),
      );
    } else {
      await areasCubit.editArea(
        id: area.id,
        requestBody: UpdateAreaRequestModel(
          name: result.name,
          nameAr: result.nameAr,
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, AreaModel area) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الحي',
      message: 'هل أنت متأكد من حذف "${area.name}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await context.read<AreasCubit>().removeArea(area.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = _canEdit;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.areasListScreen),
      appBar: GlassAppBar(
        title: Text(
          'الأحياء',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: canEdit
          ? GlassAddButton(
              label: 'إضافة حي',
              isExtended: true,
              onPressed: () => _openForm(context),
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            )
          : null,
      body: SafeArea(
        child: BlocConsumer<AreasCubit, AreasState>(
          listenWhen: (previous, current) => current is AreasActionError,
          listener: (context, state) {
            if (state case AreasActionError(:final message)) {
              showToast(message: message, state: ToastState.error);
            }
          },
          builder: (context, state) {
            return switch (state) {
              AreasLoaded(:final areas) =>
                areas.isEmpty
                    ? const _EmptyState()
                    : AdaptiveCollection<AreaModel>(
                        items: areas,
                        cardHeight: 92,
                        itemBuilder: (context, area, _) => _AreaListItem(
                          area: area,
                          onEdit: canEdit
                              ? () => _openForm(context, area: area)
                              : null,
                          onDelete: canEdit
                              ? () => _confirmDelete(context, area)
                              : null,
                        ),
                      ),
              AreasError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
              ),
              _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
            };
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: glass.surfaceGradient,
                    border: Border.all(color: glass.strokeColor),
                  ),
                  child: Icon(
                    Icons.holiday_village_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد أحياء بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول حي بالضغط على زر الإضافة',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: AppMotion.base,
          curve: AppMotion.enter,
        );
  }
}

class _AreaListItem extends StatelessWidget {
  const _AreaListItem({
    required this.area,
    required this.onEdit,
    required this.onDelete,
  });

  final AreaModel area;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
            borderRadius: radius,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: glass.brandGradient,
                          ),
                          child: const Icon(
                            Icons.holiday_village_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                area.name ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font16MediumText.copyWith(
                                  color: glass.onGlass,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                area.zoneName ?? (area.cityName ?? '—'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: glass.onGlassMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onEdit != null || onDelete != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          if (onEdit != null)
                            IconButton(
                              tooltip: 'تعديل',
                              onPressed: onEdit,
                              icon: Icon(
                                Icons.edit_outlined,
                                color: glass.onGlassMuted,
                              ),
                            ),
                          if (onDelete != null)
                            IconButton(
                              tooltip: 'حذف',
                              onPressed: onDelete,
                              icon: Icon(
                                Icons.delete_outline,
                                color: glass.error,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AreaFormDialog extends StatefulWidget {
  const _AreaFormDialog({this.initialArea});

  final AreaModel? initialArea;

  @override
  State<_AreaFormDialog> createState() => _AreaFormDialogState();
}

class _AreaFormDialogState extends State<_AreaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialArea?.name ?? '',
  );
  late final _nameArController = TextEditingController(
    text: widget.initialArea?.nameAr ?? '',
  );
  late String? _cityId = widget.initialArea?.cityId;

  bool get _isEditing => widget.initialArea != null;

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_isEditing && _cityId == null) {
      showToast(message: 'اختر المدينة', state: ToastState.error);
      return;
    }
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      nameAr: _nameArController.text.trim().isEmpty
          ? null
          : _nameArController.text.trim(),
      cityId: _cityId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل الحي' : 'إضافة حي',
        style: AppTextStyles.font18MediumText,
      ),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.8,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextFormField(
                  controller: _nameController,
                  hintText: 'اسم الحي',
                  prefixIcon: Icon(
                    Icons.holiday_village_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'اسم الحي مطلوب'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _nameArController,
                  hintText: 'الاسم بالعربي (اختياري)',
                  prefixIcon: Icon(
                    Icons.translate_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (_) => null,
                ),
                const SizedBox(height: 12),
                // The city can't change after creation (there is no such
                // field on the update request) — shown read-only once set.
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_city_outlined,
                          size: 18,
                          color: context.glass.onGlassMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.initialArea?.cityName ?? '—',
                          style: AppTextStyles.font14RegularSecondary.copyWith(
                            color: context.glass.onGlassMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  BlocBuilder<CitiesCubit, CitiesState>(
                    builder: (context, state) {
                      final cities = state is CitiesLoaded
                          ? state.cities
                          : null;
                      return CaseLookupDropdown(
                        value: _cityId,
                        icon: Icons.location_city_outlined,
                        hintText: state is CitiesLoading
                            ? 'جارٍ تحميل المدن...'
                            : 'اختر المدينة',
                        items: cities
                            ?.map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name ?? '—'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _cityId = value),
                      );
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
        TextButton(onPressed: _onConfirm, child: const Text('حفظ')),
      ],
    );
  }
}
