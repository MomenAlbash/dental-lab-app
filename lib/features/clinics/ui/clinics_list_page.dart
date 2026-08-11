import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinics_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final _scrollController = ScrollController();
  String _searchQuery = '';

  /// Last successfully loaded clinics, kept so a refresh can show the
  /// existing rows instead of replacing them with the loading skeleton.
  List<ClinicModel>? _lastClinics;

  /// The add button collapses to an icon once the user starts scrolling, so a
  /// wide button never sits on top of the rows they are reading.
  bool _addButtonExtended = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final shouldExtend = _scrollController.offset < 40;
    if (shouldExtend == _addButtonExtended) return;
    setState(() => _addButtonExtended = shouldExtend);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
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
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.clinicsListScreen),
      appBar: GlassAppBar(
        title: Text(
          'العيادات',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton:
          GlassAddButton(
            label: 'إضافة عيادة',
            isExtended: _addButtonExtended,
            onPressed: () async {
              await context.push(Routes.clinicFormScreen);
              if (context.mounted) {
                context.read<ClinicsCubit>().getClinics();
              }
            },
          ).animate().scale(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            begin: const Offset(0.6, 0.6),
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
            if (state is ClinicsLoaded) _lastClinics = state.clinics;

            // A refresh emits ClinicsLoading. Swapping the list out for the
            // skeleton at that moment unmounts the RefreshIndicator mid-pull,
            // which made pull-to-refresh look like it did nothing. Once we
            // have data, keep showing it and let the indicator run.
            final clinics = switch (state) {
              ClinicsLoaded(:final clinics) => clinics,
              ClinicsLoading() => _lastClinics,
              _ => null,
            };

            return AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.enter,
              child: switch ((state, clinics)) {
                (_, final List<ClinicModel> loaded) => ClinicsListView(
                  key: const ValueKey('clinics-loaded'),
                  clinics: _filter(loaded),
                  searchController: _searchController,
                  scrollController: _scrollController,
                  searchQuery: _searchQuery,
                  onDelete: _confirmDelete,
                ),
                // Only when there is nothing to show: if a refresh fails
                // while data is on screen, the list stays and the toast
                // reports it.
                (ClinicsError(:final message), null) => Center(
                  key: const ValueKey('clinics-error'),
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
                _ => const Padding(
                  key: ValueKey('clinics-loading'),
                  padding: EdgeInsets.only(top: 24),
                  child: GlassListSkeleton(),
                ),
              },
            );
          },
        ),
      ),
    );
  }
}
