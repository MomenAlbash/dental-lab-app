import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/countries/data/models/country_model.dart';
import 'package:dental_lab_app/features/countries/logic/countries/countries_cubit.dart';
import 'package:dental_lab_app/features/countries/logic/countries/countries_state.dart';
import 'package:flutter/material.dart';
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

  Future<void> _confirmDelete(BuildContext context, CountryModel country) async {
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
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.countriesListScreen),
      appBar: AppBar(title: Text('الدول', style: AppTextStyles.font18MediumText)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        backgroundColor: AppColorsManger.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
              CountriesLoaded(:final countries) => countries.isEmpty
                  ? Center(
                      child: Text(
                        'لا يوجد دول بعد',
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
                              itemCount: countries.length,
                              itemBuilder: (context, index) {
                                final country = countries[index];
                                return _CountryListItem(
                                  country: country,
                                  onEdit: () => _openForm(context, country: country),
                                  onDelete: () => _confirmDelete(context, country),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
              CountriesError(:final message) => Center(
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
            child: const Icon(Icons.public_outlined, color: AppColorsManger.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              country.name ?? '—',
              style: AppTextStyles.font16MediumText,
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

class _CountryFormDialog extends StatefulWidget {
  const _CountryFormDialog({this.initialName});

  final String? initialName;

  @override
  State<_CountryFormDialog> createState() => _CountryFormDialogState();
}

class _CountryFormDialogState extends State<_CountryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initialName ?? '');

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
          prefixIcon: const Icon(
            Icons.public_outlined,
            color: AppColorsManger.textSecondary,
          ),
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'اسم الدولة مطلوب' : null,
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
