import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinics_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Clinics list screen. Filtering by name mirrors the API's `search` query
/// param but is applied locally for now.
class ClinicsListPage extends StatelessWidget {
  const ClinicsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ClinicsCubit>()..getClinics(),
      child: const _ClinicsListView(),
    );
  }
}

class _ClinicsListView extends StatefulWidget {
  const _ClinicsListView();

  @override
  State<_ClinicsListView> createState() => _ClinicsListViewState();
}

class _ClinicsListViewState extends State<_ClinicsListView> {
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

  List<ClinicModel> _filter(List<ClinicModel> clinics) {
    if (_searchQuery.isEmpty) return clinics;
    final query = _searchQuery.toLowerCase();
    return clinics
        .where((clinic) => clinic.name.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _confirmDelete(ClinicModel clinic) async {
    final cubit = context.read<ClinicsCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف العيادة',
      message: 'هل أنت متأكد من حذف عيادة "${clinic.name}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteClinic(clinic.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.clinicsListScreen),
      appBar: AppBar(title: Text('العيادات', style: AppTextStyles.font18MediumText)),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () async {
            await context.push(Routes.clinicFormScreen);
            if (context.mounted) {
              context.read<ClinicsCubit>().getClinics();
            }
          },
          backgroundColor: AppColorsManger.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<ClinicsCubit, ClinicsState>(
          listener: (context, state) {
            switch (state) {
              case ClinicDeleted():
                ShowToast(message: 'تم حذف العيادة', state: toastState.success);
              case ClinicDeleteError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! ClinicDeleted && current is! ClinicDeleteError,
          builder: (context, state) {
            return switch (state) {
              ClinicsLoaded(:final clinics) => ClinicsListView(
                clinics: _filter(clinics),
                searchController: _searchController,
                searchQuery: _searchQuery,
                onDelete: _confirmDelete,
              ),
              ClinicsError(:final message) => Center(
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
