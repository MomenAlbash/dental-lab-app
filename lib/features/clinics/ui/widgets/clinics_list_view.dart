import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinic_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The clinics list section: search field plus the (locally filtered) list of
/// clinics, with pull-to-refresh.
class ClinicsListView extends StatelessWidget {
  const ClinicsListView({
    super.key,
    required this.clinics,
    required this.searchController,
    required this.searchQuery,
    required this.onDelete,
  });

  final List<ClinicModel> clinics;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<ClinicModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final contentWidth = isWide ? 700.0 : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 16,
                    vertical: 16,
                  ),
                  child: AppTextFormField(
                    controller: searchController,
                    hintText: 'ابحث باسم العيادة...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColorsManger.textSecondary,
                    ),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => searchController.clear(),
                            icon: const Icon(
                              Icons.close,
                              color: AppColorsManger.textSecondary,
                            ),
                          ),
                    validator: (_) => null,
                  ),
                ),
                Expanded(
                  child: clinics.isEmpty
                      ? Center(
                          child: Text(
                            searchQuery.isEmpty
                                ? 'لا يوجد عيادات بعد'
                                : 'لا توجد نتائج',
                            style: AppTextStyles.font14RegularSecondary,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<ClinicsCubit>().getClinics(),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 32 : 16,
                            ),
                            itemCount: clinics.length,
                            itemBuilder: (context, index) {
                              final clinic = clinics[index];
                              return ClinicListItemWidget(
                                name: clinic.name,
                                address: clinic.address ?? '',
                                cityName: clinic.cityName,
                                code: clinic.code,
                                onTap: () => context.push(
                                  Routes.clinicDetailScreen,
                                  extra: clinic.id,
                                ),
                                onEdit: () async {
                                  await context.push(
                                    Routes.clinicFormScreen,
                                    extra: clinic,
                                  );
                                  if (context.mounted) {
                                    context.read<ClinicsCubit>().getClinics();
                                  }
                                },
                                onDelete: () => onDelete(clinic),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
