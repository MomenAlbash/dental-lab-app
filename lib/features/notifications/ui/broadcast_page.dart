import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_page_model.dart';
import 'package:dental_lab_app/features/notifications/logic/broadcast/broadcast_cubit.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/logic/users/users_cubit.dart';
import 'package:dental_lab_app/features/users/logic/users/users_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Sends one notification to many people at once.
///
/// **There is no undo.** No recall endpoint exists, and the push has left the
/// server by the time the response arrives — so this screen confirms with the
/// audience named before sending, and says so plainly rather than relying on
/// the user to know.
class BroadcastPage extends StatelessWidget {
  const BroadcastPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<BroadcastCubit>()),
        // The specific-user picker is fed by the ordinary users list, which is
        // a documented endpoint. `Notifications/broadcast/recipients` would be
        // the purpose-built one, but it declares no response schema, and
        // guessing its shape to fill a picker is not worth the risk of sending
        // to the wrong people.
        BlocProvider(create: (_) => getIt<UsersCubit>()..getUsers()),
      ],
      child: const _BroadcastView(),
    );
  }
}

class _BroadcastView extends StatefulWidget {
  const _BroadcastView();

  @override
  State<_BroadcastView> createState() => _BroadcastViewState();
}

class _BroadcastViewState extends State<_BroadcastView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  BroadcastAudience _audience = BroadcastAudience.employees;
  final _selectedUsers = <String>{};

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  BroadcastNotificationRequestModel get _request =>
      BroadcastNotificationRequestModel(
        audience: _audience,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        userIds: _selectedUsers.toList(),
      );

  /// How many people this will reach, as far as the screen can tell.
  ///
  /// Only exact for the specific-user audience; the two blanket ones are the
  /// server's count, not ours, so they are described rather than numbered — a
  /// wrong number here would be worse than none.
  String get _audienceSummary {
    return switch (_audience) {
      BroadcastAudience.employees => 'كل الموظفين',
      BroadcastAudience.doctors => 'كل الأطباء',
      BroadcastAudience.specificUsers =>
        _selectedUsers.isEmpty
            ? 'لم يُختَر أحد'
            : '${_selectedUsers.length} مستخدم',
    };
  }

  Future<void> _send(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_audience == BroadcastAudience.specificUsers &&
        _selectedUsers.isEmpty) {
      showToast(message: 'اختر المستلمين أولاً', state: ToastState.error);
      return;
    }

    final cubit = context.read<BroadcastCubit>();

    // Confirmed with the audience spelled out, because the mistake this
    // guards against is not a typo — it is sending to everybody when one
    // person was meant.
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'إرسال الإشعار',
      message:
          'سيصل إلى $_audienceSummary. '
          'لا يمكن التراجع بعد الإرسال.',
      confirmText: 'إرسال',
    );
    if (confirmed != true) return;

    await cubit.send(_request);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canSend = getIt<SessionCubit>().state.canEdit(PermissionName.users);

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'إرسال إشعار',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<BroadcastCubit, BroadcastState>(
          listener: (context, state) {
            switch (state) {
              case BroadcastSent(:final audience):
                showToast(
                  message: 'أُرسل الإشعار إلى ${audience.label}',
                  state: ToastState.success,
                );
                Navigator.of(context).pop(true);
              case BroadcastFailed(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          builder: (context, state) {
            final isSending = state is BroadcastSending;

            return BlocBuilder<UsersCubit, UsersState>(
              builder: (context, usersState) {
                final users = usersState is UsersLoaded
                    ? usersState.users
                    : const <UserModel>[];

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ConstrainedBox(
                      // A form is the one place a max width is the right
                      // adaptive answer — a 1000dp message box is worse.
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'إلى من؟',
                              style: AppTextStyles.font14MediumText.copyWith(
                                color: glass.onGlass,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                for (final audience in BroadcastAudience.values)
                                  ChoiceChip(
                                    label: Text(audience.label),
                                    selected: _audience == audience,
                                    onSelected: isSending
                                        ? null
                                        : (_) => setState(
                                            () => _audience = audience,
                                          ),
                                  ),
                              ],
                            ),

                            if (_audience ==
                                BroadcastAudience.specificUsers) ...[
                              const SizedBox(height: AppSpacing.md),
                              _UserPicker(
                                users: users,
                                selected: _selectedUsers,
                                isLoading: usersState is UsersLoading,
                                onToggle: (id) => setState(() {
                                  if (!_selectedUsers.remove(id)) {
                                    _selectedUsers.add(id);
                                  }
                                }),
                              ),
                            ],

                            const SizedBox(height: AppSpacing.lg),
                            AppTextFormField(
                              controller: _titleController,
                              hintText: 'العنوان',
                              validator: (value) =>
                                  (value?.trim().isEmpty ?? true)
                                  ? 'العنوان مطلوب'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppTextFormField(
                              controller: _bodyController,
                              hintText: 'نص الإشعار',
                              maxLines: 4,
                              validator: (value) =>
                                  (value?.trim().isEmpty ?? true)
                                  ? 'النص مطلوب'
                                  : null,
                            ),

                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: glass.warning.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: glass.warning.withValues(alpha: 0.25),
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.glass,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.campaign_outlined,
                                    size: 18,
                                    color: glass.warning,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'سيصل إلى $_audienceSummary'
                                      ' — لا يمكن التراجع.',
                                      style: AppTextStyles.font12RegularHint
                                          .copyWith(color: glass.warning),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.md),
                            CustomButtonWidget(
                              buttonText: 'إرسال',
                              onPressed: !canSend || isSending
                                  ? null
                                  : () => _send(context),
                            ),
                            if (!canSend)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'لا تملك صلاحية إرسال الإشعارات',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.font12RegularHint
                                      .copyWith(color: glass.onGlassMuted),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _UserPicker extends StatelessWidget {
  const _UserPicker({
    required this.users,
    required this.selected,
    required this.isLoading,
    required this.onToggle,
  });

  final List<UserModel> users;
  final Set<String> selected;
  final bool isLoading;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    if (isLoading) {
      return Text(
        'جارٍ تحميل المستخدمين…',
        style: AppTextStyles.font12RegularHint.copyWith(
          color: glass.onGlassMuted,
        ),
      );
    }

    if (users.isEmpty) {
      return Text(
        'لا يوجد مستخدمون',
        style: AppTextStyles.font12RegularHint.copyWith(
          color: glass.onGlassMuted,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];

          return CheckboxListTile(
            dense: true,
            value: selected.contains(user.id),
            onChanged: (_) => onToggle(user.id),
            title: Text(
              user.linkedName.trim().isEmpty
                  ? (user.username ?? '—')
                  : user.linkedName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlass,
              ),
            ),
          );
        },
      ),
    );
  }
}
