import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/departments/data/models/department_model.dart';
import 'package:dental_lab_app/features/departments/logic/departments/departments_cubit.dart';
import 'package:dental_lab_app/features/departments/logic/departments/departments_state.dart';
import 'package:dental_lab_app/features/departments/ui/widgets/department_card.dart';
import 'package:dental_lab_app/features/departments/ui/widgets/department_form_sheet.dart';
import 'package:dental_lab_app/features/departments/ui/widgets/department_stages_picker.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/repos/restoration_types_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The laboratory's departments, and the restoration stages each one owns.
class DepartmentsPage extends StatelessWidget {
  const DepartmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DepartmentsCubit>()..load(),
      child: const _DepartmentsView(),
    );
  }
}

class _DepartmentsView extends StatefulWidget {
  const _DepartmentsView();

  @override
  State<_DepartmentsView> createState() => _DepartmentsViewState();
}

class _DepartmentsViewState extends State<_DepartmentsView> {
  /// Loaded once and handed to both the form and the stage picker.
  ///
  /// `RestorationTypeModel` already carries its own stages, so linking a
  /// department to a stage needs no second catalogue request.
  List<RestorationTypeModel> _types = const [];
  List<EmployeeModel> _employees = const [];

  @override
  void initState() {
    super.initState();
    _loadPickerData();
  }

  Future<void> _loadPickerData() async {
    final typesResult = await getIt<RestorationTypesRepo>()
        .getRestorationTypes();
    final employeesResult = await getIt<EmployeesRepo>().getEmployees();
    if (!mounted) return;

    // A failure here is not worth an error screen: the list still reads, and
    // only the pickers are poorer for it.
    setState(() {
      typesResult.fold((_) {}, (types) {
        _types = [
          for (final type in types)
            if (type.isActive) type,
        ];
      });
      employeesResult.fold((_) {}, (employees) => _employees = employees);
    });
  }

  Future<void> _openForm([DepartmentModel? department]) async {
    final cubit = context.read<DepartmentsCubit>();
    final state = cubit.state;

    final body = await showDepartmentFormSheet(
      context,
      initial: department,
      allDepartments: state is DepartmentsLoaded ? state.departments : const [],
      types: _types,
      employees: _employees,
      ownerByStageId: cubit.stageOwners(exclude: department?.id),
    );
    if (body == null) return;

    if (department == null) {
      await cubit.createDepartment(body);
    } else {
      await cubit.updateDepartment(id: department.id, body: body);
    }
  }

  /// The stage link on its own, without walking the whole form.
  ///
  /// This is the edit a lab actually makes repeatedly — the name is settled
  /// after the first day, the routing is not.
  Future<void> _linkStages(DepartmentModel department) async {
    final cubit = context.read<DepartmentsCubit>();

    final result = await showDepartmentStagesPicker(
      context,
      types: _types,
      selectedIds: {for (final stage in department.stages) stage.id},
      ownerByStageId: cubit.stageOwners(exclude: department.id),
    );
    if (result == null) return;

    await cubit.setStages(department: department, stageIds: result.toList());
  }

  Future<void> _delete(DepartmentModel department) async {
    final cubit = context.read<DepartmentsCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف القسم',
      message:
          'سيتم حذف "${department.displayName}". '
          'مراحله تُحرَّر ولا تُحذف، لكنها ستبقى بلا قسم حتى تربطها من جديد.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.deleteDepartment(department.id);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.caseWorkflow,
    );

    return BlocConsumer<DepartmentsCubit, DepartmentsState>(
      listener: (context, state) {
        if (state is DepartmentsMessage) {
          showToast(
            message: state.message,
            state: state.isError ? ToastState.error : ToastState.success,
          );
        }
      },
      builder: (context, state) {
        final loaded = state is DepartmentsLoaded ? state : null;

        return GlassScaffold(
          appBar: GlassAppBar(
            title: Text(
              'الأقسام',
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            actions: [
              if (loaded != null)
                IconButton(
                  tooltip: loaded.includeInactive
                      ? 'إخفاء المعطّلة'
                      : 'إظهار المعطّلة',
                  onPressed: () => context.read<DepartmentsCubit>().load(
                    includeInactive: !loaded.includeInactive,
                  ),
                  icon: Icon(
                    loaded.includeInactive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              if (canEdit)
                IconButton(
                  tooltip: 'إضافة قسم',
                  onPressed: loaded?.isBusy ?? false ? null : () => _openForm(),
                  icon: const Icon(Icons.add),
                ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          body: SafeArea(
            child: switch (state) {
              DepartmentsError(:final message) => _Message(text: message),
              DepartmentsLoaded(:final departments) =>
                departments.isEmpty
                    ? const _Empty()
                    : AdaptiveCollection<DepartmentModel>(
                        items: departments,
                        cardHeight: 240,
                        onRefresh: () =>
                            context.read<DepartmentsCubit>().load(),
                        itemBuilder: (context, department, _) => DepartmentCard(
                          department: department,
                          isBusy: loaded?.isBusy ?? false,
                          onEdit: () => _openForm(department),
                          onLinkStages: () => _linkStages(department),
                          onDelete: () => _delete(department),
                        ),
                      ),
              _ => const _Skeleton(),
            },
          ),
        );
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.screen),
    children: const [
      GlassSkeletonBox(height: 180),
      SizedBox(height: AppSpacing.md),
      GlassSkeletonBox(height: 180),
    ],
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apartment_outlined, size: 44, color: glass.onGlassMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد أقسام بعد',
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'القسم هو ما يربط موظفيك بمراحل التصنيع — '
              'بدونه لا تعرف المرحلة إلى من تُسنَد.',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.font14RegularSecondary.copyWith(
          color: context.glass.onGlassMuted,
        ),
      ),
    ),
  );
}
