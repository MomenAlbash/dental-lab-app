import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_filter_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_filters_sheet.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctors_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final _scrollController = ScrollController();
  String _searchQuery = '';

  /// Last successfully loaded doctors, kept so a refresh can show the existing
  /// rows instead of replacing them with the loading skeleton.
  List<DoctorModel>? _lastDoctors;

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
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.doctorsListScreen),
      appBar: GlassAppBar(
        title: Text(
          'الدكاترة',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
        actions: [
          BlocBuilder<DoctorsCubit, DoctorsState>(
            builder: (context, state) {
              final activeCount = context
                  .read<DoctorsCubit>()
                  .filters
                  .activeCount;
              return GlassFilterButton(
                activeCount: activeCount,
                onPressed: () => openDoctorFiltersSheet(context),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) =>
            GlassAddButton(
              label: 'إضافة دكتور',
              isExtended: _addButtonExtended,
              onPressed: () async {
                await context.push(Routes.doctorFormScreen);
                if (context.mounted) {
                  context.read<DoctorsCubit>().getDoctors();
                }
              },
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
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
            if (state is DoctorsLoaded) _lastDoctors = state.doctors;

            // A refresh emits DoctorsLoading. Swapping the list out for the
            // skeleton at that moment unmounts the RefreshIndicator mid-pull,
            // which made pull-to-refresh look like it did nothing. Once we
            // have data, keep showing it and let the indicator run.
            final doctors = switch (state) {
              DoctorsLoaded(:final doctors) => doctors,
              DoctorsLoading() => _lastDoctors,
              _ => null,
            };

            // Cross-fades loading → data → error instead of the content
            // snapping into place.
            return AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.enter,
              child: switch ((state, doctors)) {
                (_, final List<DoctorModel> loaded) => DoctorsListView(
                  key: const ValueKey('doctors-loaded'),
                  doctors: _filter(loaded),
                  searchController: _searchController,
                  scrollController: _scrollController,
                  searchQuery: _searchQuery,
                  onDelete: _confirmDelete,
                ),
                // Only when there is nothing to show: if a refresh fails while
                // data is on screen, the list stays and the toast reports it.
                (DoctorsError(:final message), null) => Center(
                  key: const ValueKey('doctors-error'),
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
                  key: ValueKey('doctors-loading'),
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
