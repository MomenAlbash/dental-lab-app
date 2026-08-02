import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
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
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.citiesListScreen),
      appBar: AppBar(title: Text('المدن', style: AppTextStyles.font18MediumText)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        backgroundColor: AppColorsManger.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
              CitiesLoaded(:final cities) => cities.isEmpty
                  ? Center(
                      child: Text(
                        'لا يوجد مدن بعد',
                        style: AppTextStyles.font14RegularSecondary,
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 600;
                        final contentWidth = isWide ? 700.0 : constraints.maxWidth;

                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: contentWidth),
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: isWide ? 32 : 16,
                                vertical: 16,
                              ),
                              itemCount: cities.length,
                              itemBuilder: (context, index) {
                                final city = cities[index];
                                return _CityListItem(
                                  city: city,
                                  onEdit: () => _openForm(context, city: city),
                                  onDelete: () => _confirmDelete(context, city),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
              CitiesError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColorsManger.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorsManger.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColorsManger.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_city_outlined, color: AppColorsManger.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city.name ?? '—', style: AppTextStyles.font16MediumText),
                if (city.country?.name != null)
                  Text(
                    city.country!.name!,
                    style: AppTextStyles.font12RegularHint,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColorsManger.textSecondary),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColorsManger.error),
          ),
        ],
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
  late final _nameController = TextEditingController(text: widget.initialCity?.name ?? '');
  late String? _countryId = widget.initialCity?.countryId;

  bool get _isEditing => widget.initialCity != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((name: _nameController.text.trim(), countryId: _countryId));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل المدينة' : 'إضافة مدينة',
        style: AppTextStyles.font18MediumText,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextFormField(
              controller: _nameController,
              hintText: 'اسم المدينة',
              prefixIcon: const Icon(
                Icons.location_city_outlined,
                color: AppColorsManger.textSecondary,
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'اسم المدينة مطلوب' : null,
            ),
            const SizedBox(height: 12),
            BlocBuilder<CountriesCubit, CountriesState>(
              builder: (context, state) {
                final countries = state is CountriesLoaded ? state.countries : null;
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
