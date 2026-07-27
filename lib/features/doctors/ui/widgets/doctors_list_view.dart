import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The doctors list section: search field plus the (locally filtered) list of
/// doctors, with pull-to-refresh.
class DoctorsListView extends StatelessWidget {
  const DoctorsListView({
    super.key,
    required this.doctors,
    required this.searchController,
    required this.searchQuery,
    required this.onDelete,
  });

  final List<DoctorModel> doctors;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<DoctorModel> onDelete;

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
                    hintText: 'ابحث باسم الدكتور...',
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
                  child: doctors.isEmpty
                      ? Center(
                          child: Text(
                            searchQuery.isEmpty
                                ? 'لا يوجد دكاترة بعد'
                                : 'لا توجد نتائج',
                            style: AppTextStyles.font14RegularSecondary,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () =>
                              context.read<DoctorsCubit>().getDoctors(),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 32 : 16,
                            ),
                            itemCount: doctors.length,
                            itemBuilder: (context, index) {
                              final doctor = doctors[index];
                              return DoctorListItemWidget(
                                fullName: doctor.fullName,
                                phoneNumber: doctor.phoneNumber ?? '',
                                clinicName: doctor.clinicName ?? '',
                                onTap: () => context.push(
                                  Routes.doctorDetailScreen,
                                  extra: doctor.id,
                                ),
                                onEdit: () async {
                                  await context.push(
                                    Routes.doctorFormScreen,
                                    extra: doctor,
                                  );
                                  if (context.mounted) {
                                    context.read<DoctorsCubit>().getDoctors();
                                  }
                                },
                                onDelete: () => onDelete(doctor),
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
