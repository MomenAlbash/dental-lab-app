import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctors_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DoctorsListPage extends StatelessWidget {
  const DoctorsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DoctorsCubit>()..getDoctors(),
      child: const _DoctorsListView(),
    );
  }
}

class _DoctorsListView extends StatefulWidget {
  const _DoctorsListView();

  @override
  State<_DoctorsListView> createState() => _DoctorsListViewState();
}

class _DoctorsListViewState extends State<_DoctorsListView> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DoctorModel> _filter(List<DoctorModel> doctors) {
    if (_searchQuery.isEmpty) return doctors;
    final query = _searchQuery.toLowerCase();
    return doctors
        .where((doctor) => doctor.fullName.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _confirmDelete(DoctorModel doctor) async {
    final cubit = context.read<DoctorsCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الدكتور',
      message: 'هل أنت متأكد من حذف الدكتور "${doctor.fullName}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteDoctor(doctor.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.doctorsListScreen),
      appBar: AppBar(title: Text('الدكاترة', style: AppTextStyles.font18MediumText)),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () async {
            await context.push(Routes.doctorFormScreen);
            if (context.mounted) {
              context.read<DoctorsCubit>().getDoctors();
            }
          },
          backgroundColor: AppColorsManger.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<DoctorsCubit, DoctorsState>(
          listener: (context, state) {
            switch (state) {
              case DoctorDeleted():
                ShowToast(message: 'تم حذف الدكتور', state: toastState.success);
              case DoctorDeleteError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! DoctorDeleted && current is! DoctorDeleteError,
          builder: (context, state) {
            return switch (state) {
              DoctorsLoaded(:final doctors) => DoctorsListView(
                doctors: _filter(doctors),
                searchController: _searchController,
                searchQuery: _searchQuery,
                onDelete: _confirmDelete,
              ),
              DoctorsError(:final message) => Center(
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
