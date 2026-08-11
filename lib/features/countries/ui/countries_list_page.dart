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
import 'package:dental_lab_app/features/countries/data/models/country_model.dart';
import 'package:dental_lab_app/features/countries/logic/countries/countries_cubit.dart';
import 'package:dental_lab_app/features/countries/logic/countries/countries_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Countries list screen — plain CRUD (`/api/clinic/Countries`); a country
/// is just a name, referenced by cities' `countryId`.
class CountriesListPage extends StatelessWidget {
  const CountriesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CountriesCubit>()..getCountries(),
      child: const _CountriesListView(),
    );
  }
}

class _CountriesListView extends StatelessWidget {
  const _CountriesListView();

  Future<void> _openForm(BuildContext context, {CountryModel? country}) async {
    final cubit = context.read<CountriesCubit>();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _CountryFormDialog(initialName: country?.name),
    );
    if (name == null) return;

    if (country == null) {
      await cubit.addCountry(name);
    } else {
      await cubit.editCountry(id: country.id, name: name);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CountryModel country,
  ) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الدولة',
      message: 'هل أنت متأكد من حذف "${country.name}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await context.read<CountriesCubit>().removeCountry(country.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.countriesListScreen),
      appBar: GlassAppBar(
        title: Text(
          'الدول',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton:
          GlassAddButton(
            label: 'إضافة دولة',
            isExtended: true,
            onPressed: () => _openForm(context),
          ).animate().scale(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            begin: const Offset(0.6, 0.6),
          ),
      body: SafeArea(
        child: BlocConsumer<CountriesCubit, CountriesState>(
          listenWhen: (previous, current) => current is CountriesActionError,
          listener: (context, state) {
            if (state case CountriesActionError(:final message)) {
              ShowToast(message: message, state: toastState.error);
            }
          },
          builder: (context, state) {
            return switch (state) {
              CountriesLoaded(:final countries) =>
                countries.isEmpty
                    ? _EmptyState()
                    : AdaptiveCollection<CountryModel>(
                        items: countries,
                        // A country row is a single line of text with two icon
                        // buttons — much shorter than the app's usual card.
                        cardHeight: 84,
                        itemBuilder: (context, country, _) => _CountryListItem(
                          country: country,
                          onEdit: () => _openForm(context, country: country),
                          onDelete: () => _confirmDelete(context, country),
                        ),
                      ),
              CountriesError(:final message) => Center(
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
                    Icons.public_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد دول بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول دولة بالضغط على زر الإضافة',
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

class _CountryListItem extends StatelessWidget {
  const _CountryListItem({
    required this.country,
    required this.onEdit,
    required this.onDelete,
  });

  final CountryModel country;
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
                            Icons.public_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            country.name ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.font16MediumText.copyWith(
                              color: glass.onGlass,
                            ),
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

class _CountryFormDialog extends StatefulWidget {
  const _CountryFormDialog({this.initialName});

  final String? initialName;

  @override
  State<_CountryFormDialog> createState() => _CountryFormDialogState();
}

class _CountryFormDialogState extends State<_CountryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialName ?? '',
  );

  bool get _isEditing => widget.initialName != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل الدولة' : 'إضافة دولة',
        style: AppTextStyles.font18MediumText,
      ),
      content: Form(
        key: _formKey,
        child: AppTextFormField(
          controller: _nameController,
          hintText: 'اسم الدولة',
          prefixIcon: Icon(
            Icons.public_outlined,
            color: context.glass.onGlassMuted,
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'اسم الدولة مطلوب'
              : null,
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
