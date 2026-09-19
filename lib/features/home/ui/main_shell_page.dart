import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/notifications/push_notification_service.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:dental_lab_app/core/widgets/app_bottom_nav_bar.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/assistant/ui/assistant_sheet.dart';
import 'package:dental_lab_app/features/cases/ui/cases_due_page.dart';
import 'package:dental_lab_app/features/cases/ui/cases_list_page.dart';
import 'package:dental_lab_app/features/home/ui/home_page.dart';
import 'package:dental_lab_app/features/notifications/ui/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The app's main screen after login: four tabs behind a floating bottom bar,
/// with creating a case raised into the middle of it.
///
/// The drawer is still there and still reaches every feature — the bar is a
/// shortcut to the handful of screens used constantly, not a replacement for
/// it. Tabs are kept in an [IndexedStack] so switching away and back does not
/// discard the cases list's filters, scroll position, or loaded page.
class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  static const _casesIndex = 1;

  static const _destinations = [
    AppBottomNavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'الرئيسية',
    ),
    AppBottomNavDestination(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder_rounded,
      label: 'الحالات',
    ),
    AppBottomNavDestination(
      icon: Icons.event_outlined,
      selectedIcon: Icons.event_rounded,
      label: 'المواعيد',
    ),
    AppBottomNavDestination(
      icon: Icons.notifications_none_rounded,
      selectedIcon: Icons.notifications_rounded,
      label: 'الإشعارات',
    ),
  ];

  static const _notificationsIndex = 3;

  int _index = 0;

  /// Bumped after a case is created so the cases tab remounts and refetches.
  /// The list's cubit is created inside [CasesListPage], below this widget, so
  /// there is nothing here to call `getCases()` on — and a stale list that
  /// omits the case the user just added is the one outcome this flow must not
  /// produce.
  int _casesGeneration = 0;

  late final ValueNotifier<int> _notificationTapped =
      getIt<PushNotificationService>().notificationTapped;

  @override
  void initState() {
    super.initState();
    _notificationTapped.addListener(_onNotificationTapped);
  }

  @override
  void dispose() {
    _notificationTapped.removeListener(_onNotificationTapped);
    super.dispose();
  }

  // The push payload carries no case reference yet (see
  // PushNotificationService.notificationTapped), so a tap can only open the
  // tab — not deep-link to the case the notification was about.
  void _onNotificationTapped() {
    if (!mounted) return;
    setState(() => _index = _notificationsIndex);
  }

  void _onDestinationSelected(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  /// The raised `+` always starts case creation regardless of which tab is
  /// showing, so it is gated on the Cases permission itself rather than on
  /// whatever screen happens to be behind it.
  bool _canAddCase() =>
      getIt<SessionCubit>().state.canEdit(PermissionName.cases);

  Future<void> _addCase() async {
    if (!_canAddCase()) {
      showToast(message: 'لا تملك صلاحية إضافة حالة', state: ToastState.error);
      return;
    }

    // The form pops `true` only after the case is actually saved. Backing out
    // of it leaves the user exactly where they were — no tab jump, and no
    // remount that would throw away the cases list's filters and scroll
    // position for nothing.
    final created = await context.push<bool>(Routes.caseFormScreen);
    if (!mounted || created != true) return;
    setState(() {
      _index = _casesIndex;
      _casesGeneration++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final pages = [
      const _StubTab(
        title: 'الرئيسية',
        showScanAction: true,
        child: HomeBody(),
      ),
      CasesListPage(key: ValueKey(_casesGeneration), showAddButton: false),
      // Brings its own scaffold: the filter action sits in the app bar and
      // needs the same cubit as the list under it.
      const CasesDueTab(),
      const NotificationsTab(),
    ];

    return PopScope(
      // Back from a secondary tab returns to home instead of leaving the app,
      // which is what the hardware button means inside a tabbed shell.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _index = 0);
      },
      child: Stack(
        children: [
          // Inflating the bottom inset — rather than padding each page — means
          // every tab's own SafeArea lifts its content clear of the floating
          // bar without any of them knowing the bar exists.
          MediaQuery(
            data: mediaQuery.copyWith(
              padding: mediaQuery.padding.copyWith(
                bottom: mediaQuery.padding.bottom + AppBottomNavBar.totalHeight,
              ),
            ),
            child: IndexedStack(index: _index, children: pages),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                // From tablet up GlassScaffold pins the drawer as a column on
                // the leading edge; the bar floats over the page, not over it.
                padding: EdgeInsetsDirectional.only(
                  start: AdaptiveLayout.of(context) == AdaptiveFormFactor.mobile
                      ? 0
                      : GlassScaffold.pinnedNavWidth,
                ),
                child: AppBottomNavBar(
                  destinations: _destinations,
                  currentIndex: _index,
                  onDestinationSelected: _onDestinationSelected,
                  onPrimaryAction: _addCase,
                  primaryActionLabel: 'إضافة حالة',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scaffold for the tabs that are still placeholders. The cases tab brings its
/// own (with its filter action and add-button wiring), so this covers only the
/// three that have nothing but a title and a message.
class _StubTab extends StatelessWidget {
  const _StubTab({
    required this.title,
    required this.child,
    this.showScanAction = false,
  });

  final String title;
  final Widget child;

  /// The home tab carries the scanner: it is the screen a technician opens
  /// with a tray in front of them, and scanning the ticket is how they get to
  /// the work without knowing its number.
  final bool showScanAction;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.homeScreen),
      appBar: GlassAppBar(
        title: Text(
          title,
          style: AppTextStyles.font18MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
        actions: [
          // Beside the scanner because it answers the same kind of question —
          // "find me the thing I am thinking of" — just in words rather than
          // from a barcode.
          IconButton(
            tooltip: 'المساعد',
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: () => showAssistantSheet(context),
          ),
          if (showScanAction)
            IconButton(
              tooltip: 'مسح باركود حالة أو تعويض',
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => context.push(Routes.barcodeScannerScreen),
            ),
        ],
      ),
      body: SafeArea(child: child),
    );
  }
}
