import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_enums.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/repos/scanner_sessions_repo.dart';
import 'package:dental_lab_app/features/scanner_sessions/logic/scanner_sessions/scanner_sessions_cubit.dart';
import 'package:dental_lab_app/features/scanner_sessions/logic/scanner_sessions/scanner_sessions_state.dart';
import 'package:dental_lab_app/features/scanner_sessions/ui/widgets/assign_representative_sheet.dart';
import 'package:dental_lab_app/features/scanner_sessions/ui/widgets/scanner_session_list_item.dart';
import 'package:dental_lab_app/features/scanner_sessions/ui/widgets/session_messages_sheet.dart';
import 'package:dental_lab_app/features/scanner_sessions/ui/widgets/scanner_review_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The scanner-session dispatch board.
///
/// Gated on `ScannerControl`: without it the user gets a "no access" panel
/// rather than an empty list, which would read as "the lab has no sessions".
class ScannerSessionsPage extends StatelessWidget {
  const ScannerSessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, Permissions>(
      bloc: getIt<SessionCubit>(),
      builder: (context, permissions) {
        final canRead = permissions.canRead(PermissionName.scannerControl);

        return BlocProvider(
          create: (_) {
            final cubit = getIt<ScannerSessionsCubit>();
            if (canRead) cubit.getSessions();
            return cubit;
          },
          child: _ScannerSessionsView(canRead: canRead),
        );
      },
    );
  }
}

class _ScannerSessionsView extends StatelessWidget {
  const _ScannerSessionsView({required this.canRead});

  final bool canRead;

  /// Opens the thread with the doctor about one appointment.
  ///
  /// Titled with the doctor as well as the session number: the number is what
  /// the lab files it under, the name is what the person opening it is
  /// actually looking for.
  Future<void> _openMessages(
    BuildContext context,
    ScannerSessionModel session,
  ) {
    final doctor = session.doctorName?.trim();

    return showSessionMessagesSheet(
      context,
      sessionId: session.id,
      title: (doctor == null || doctor.isEmpty)
          ? session.title
          : '${session.title} · $doctor',
    );
  }

  Future<void> _assign(
    BuildContext context,
    ScannerSessionModel session,
  ) async {
    final cubit = context.read<ScannerSessionsCubit>();

    // The zone owns who may take a session, so the list is fetched per session
    // rather than being a global employee picker.
    final result = await getIt<ScannerSessionsRepo>()
        .getEligibleRepresentatives(session.id);
    if (!context.mounted) return;

    final representatives = result.fold((failure) {
      showToast(message: failure.errorMessage, state: ToastState.error);
      return null;
    }, (value) => value);
    if (representatives == null || !context.mounted) return;

    final choice = await showAssignRepresentativeSheet(
      context,
      session: session,
      representatives: representatives,
    );
    if (choice == null) return;

    await cubit.assignRepresentative(
      id: session.id,
      representativeUserId: choice.userId,
      note: choice.note,
    );
  }

  Future<void> _review(
    BuildContext context,
    ScannerSessionModel session,
  ) async {
    final cubit = context.read<ScannerSessionsCubit>();

    final choice = await showScannerReviewSheet(context, session: session);
    if (choice == null) return;

    // There is no dedicated review/accept-reject endpoint — `PUT
    // /scanner-sessions/{id}/review` is a route the client had built ahead
    // of the backend and 404s live (it belongs to the representative's own
    // app for a different purpose). The session's own status is the real,
    // live mechanism Control has for recording the outcome: accepted closes
    // it as completed, a redo request cancels this attempt so a new session
    // can be booked for it.
    await cubit.setStatus(
      id: session.id,
      status: choice.approve
          ? ScannerSessionStatus.completed
          : ScannerSessionStatus.cancelled,
      note: choice.note,
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.scannerSessionsScreen),
      appBar: GlassAppBar(
        title: Text(
          'جلسات السكنر',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child: !canRead
            ? const _NoAccess()
            : BlocConsumer<ScannerSessionsCubit, ScannerSessionsState>(
                listener: (context, state) {
                  if (state is ScannerSessionActionSuccess) {
                    showToast(
                      message: state.message,
                      state: ToastState.success,
                    );
                  } else if (state is ScannerSessionActionError) {
                    showToast(message: state.message, state: ToastState.error);
                  }
                },
                builder: (context, state) => switch (state) {
                  ScannerSessionsLoaded(:final sessions) =>
                    sessions.isEmpty
                        ? const _Empty()
                        : AdaptiveCollection<ScannerSessionModel>(
                            items: sessions,
                            onRefresh: () => context
                                .read<ScannerSessionsCubit>()
                                .getSessions(),
                            cardHeight: 190,
                            itemBuilder: (context, session, _) =>
                                ScannerSessionListItem(
                                  session: session,
                                  onAssign: () => _assign(context, session),
                                  // Only a session that has a scan attached
                                  // and is not already closed has something
                                  // for Control to act on.
                                  onReview:
                                      session.hasScans &&
                                          (session.status?.isOpen ?? false)
                                      ? () => _review(context, session)
                                      : null,
                                  onMessages: () => _openMessages(
                                    context,
                                    session,
                                  ),
                                ),
                          ),
                  ScannerSessionsError(:final message) => _Message(
                    text: message,
                  ),
                  _ => const _Skeleton(),
                },
              ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.screen),
    children: const [
      GlassSkeletonBox(height: 150),
      SizedBox(height: AppSpacing.md),
      GlassSkeletonBox(height: 150),
      SizedBox(height: AppSpacing.md),
      GlassSkeletonBox(height: 150),
    ],
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) =>
      const _Message(text: 'لا توجد جلسات سكنر');
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

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 40, color: glass.onGlassMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا تملك صلاحية جلسات السكنر',
              textAlign: TextAlign.center,
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
