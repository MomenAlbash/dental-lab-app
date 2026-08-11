import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_state.dart';
import 'package:dental_lab_app/features/countries/logic/countries/countries_cubit.dart';
import 'package:dental_lab_app/features/countries/logic/countries/countries_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cities list screen — plain CRUD (`/api/clinic/Cities`); a city has a name
/// and an optional country.
class CitiesListPage extends StatelessWidget {
  const CitiesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CitiesCubit>()..getCities()),
        BlocProvider(create: (_) => getIt<CountriesCubit>()..getCountries()),
      ],
      child: const _CitiesListView(),
    );
  }
}

class _CitiesListView extends StatelessWidget {
  const _CitiesListView();

  Future<void> _openForm(BuildContext context, {CityModel? city}) async {
    final citiesCubit = context.read<CitiesCubit>();
    final countriesCubit = context.read<CountriesCubit>();
    final result = await showDialog<({String name, String? countryId})>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: countriesCubit,
        child: _CityFormDialog(initialCity: city),
      ),
    );
    if (result == null) return;

    if (city == null) {
      await citiesCubit.addCity(name: result.name, countryId: result.countryId);
    } else {
      await citiesCubit.editCity(
        id: city.id,
        name: result.name,
        countryId: result.countryId,
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, CityModel city) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف المدينة',
      message: 'هل أنت متأكد من حذف "${city.name}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await context.read<CitiesCubit>().removeCity(city.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.citiesListScreen),
      appBar: GlassAppBar(
        title: Text(
          'المدن',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton:
          GlassAddButton(
            label: 'إضافة مدينة',
            isExtended: true,
            onPressed: () => _openForm(context),
          ).animate().scale(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            begin: const Offset(0.6, 0.6),
          ),
      body: SafeArea(
        child: BlocConsumer<CitiesCubit, CitiesState>(
          listenWhen: (previous, current) => current is CitiesActionError,
          listener: (context, state) {
            if (state case CitiesActionError(:final message)) {
              ShowToast(message: message, state: toastState.error);
            }
          },
          builder: (context, state) {
            return switch (state) {
              CitiesLoaded(:final cities) =>
                cities.isEmpty
                    ? _EmptyState()
                    : AdaptiveCollection<CityModel>(
                        items: cities,
                        // A city row is a single line of text with two icon
                        // buttons — much shorter than the app's usual card.
                        cardHeight: 84,
                        itemBuilder: (context, city, _) => _CityListItem(
                          city: city,
                          onEdit: () => _openForm(context, city: city),
                          onDelete: () => _confirmDelete(context, city),
                        ),
                      ),
              CitiesError(:final message) => Center(
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
                    Icons.location_city_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد مدن بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول مدينة بالضغط على زر الإضافة',
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

class _CityListItem extends StatelessWidget {
  const _CityListItem({
    required this.city,
    required this.onEdit,
    required this.onDelete,
  });

  final CityModel city;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                            Icons.location_city_outlined,
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
                                city.name ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font16MediumText.copyWith(
                                  color: glass.onGlass,
                                ),
                              ),
                              if (city.country?.name != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  city.country!.name!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.font12RegularHint
                                      .copyWith(color: glass.onGlassMuted),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton(
                          tooltip: 'تعديل',
                          onPressed: onEdit,
                          icon: Icon(
                            Icons.edit_outlined,
                            color: glass.onGlassMuted,
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          onPressed: onDelete,
                          icon: Icon(Icons.delete_outline, color: glass.error),
                        ),
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

class _CityFormDialog extends StatefulWidget {
  const _CityFormDialog({this.initialCity});

  final CityModel? initialCity;

  @override
  State<_CityFormDialog> createState() => _CityFormDialogState();
}

class _CityFormDialogState extends State<_CityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialCity?.name ?? '',
  );
  late String? _countryId = widget.initialCity?.countryId;

  bool get _isEditing => widget.initialCity != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(
      context,
    ).pop((name: _nameController.text.trim(), countryId: _countryId));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل المدينة' : 'إضافة مدينة',
        style: AppTextStyles.font18MediumText,
      ),
      // A bounded width is required because AlertDialog measures its content's
      // intrinsic width, which the lookup dropdown's lazy list can't provide;
      // the height cap + scroll keeps it from overflowing once the country
      // suggestion list expands with the keyboard up.
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
                  hintText: 'اسم المدينة',
                  prefixIcon: Icon(
                    Icons.location_city_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'اسم المدينة مطلوب'
                      : null,
                ),
                const SizedBox(height: 12),
                BlocBuilder<CountriesCubit, CountriesState>(
                  builder: (context, state) {
                    final countries = state is CountriesLoaded
                        ? state.countries
                        : null;
                    return CaseLookupDropdown(
                      value: _countryId,
                      icon: Icons.public_outlined,
                      hintText: state is CountriesLoading
                          ? 'جارٍ تحميل الدول...'
                          : 'اختر الدولة (اختياري)',
                      items: countries
                          ?.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name ?? '—'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _countryId = value),
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
