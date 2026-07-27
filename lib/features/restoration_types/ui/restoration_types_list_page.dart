import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_state.dart';
import 'package:dental_lab_app/features/restoration_types/ui/widgets/restoration_types_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RestorationTypesListPage extends StatelessWidget {
  const RestorationTypesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RestorationTypesCubit>()..getRestorationTypes(),
      child: const _RestorationTypesListView(),
    );
  }
}

class _RestorationTypesListView extends StatelessWidget {
  const _RestorationTypesListView();

  Future<void> _confirmDelete(
    BuildContext context,
    RestorationTypeModel type,
  ) async {
    final cubit = context.read<RestorationTypesCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف التعويض',
      message: 'هل أنت متأكد من حذف تعويض "${type.displayName}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteRestorationType(type.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(
        currentRoute: Routes.restorationTypesListScreen,
      ),
      appBar: AppBar(
        title: Text('التعويضات السنية', style: AppTextStyles.font18MediumText),
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () async {
            await context.push(Routes.restorationTypeFormScreen);
            if (context.mounted) {
              context.read<RestorationTypesCubit>().getRestorationTypes();
            }
          },
          backgroundColor: AppColorsManger.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<RestorationTypesCubit, RestorationTypesState>(
          listener: (context, state) {
            switch (state) {
              case RestorationTypeDeleted():
                ShowToast(message: 'تم حذف التعويض', state: toastState.success);
              case RestorationTypeDeleteError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! RestorationTypeDeleted &&
              current is! RestorationTypeDeleteError,
          builder: (context, state) {
            return switch (state) {
              RestorationTypesLoaded(:final types) =>
                types.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد تعويضات بعد',
                          style: AppTextStyles.font14RegularSecondary,
                        ),
                      )
                    : RestorationTypesListView(
                        types: types,
                        onDelete: (type) => _confirmDelete(context, type),
                      ),
              RestorationTypesError(:final message) => Center(
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
