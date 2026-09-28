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
import 'package:dental_lab_app/core/widgets/laboratory_picker_dialog.dart';
import 'package:dental_lab_app/features/assistant/ui/assistant_sheet.dart';
import 'package:dental_lab_app/features/cases/ui/cases_due_page.dart';
import 'package:dental_lab_app/features/cases/ui/cases_list_page.dart';
import 'package:dental_lab_app/features/home/ui/home_page.dart';
import 'package:dental_lab_app/features/home/ui/widgets/scanner_action_button.dart';
import 'package:dental_lab_app/features/notifications/ui/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

/// The shell's tabs, by identity rather than position: which of them show
/// depends on the user's permissions, so an index would shift under them.
enum _ShellTab {
  home(
    AppBottomNavDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'الرئيسية',
    ),
  ),
  cases(
    AppBottomNavDestination(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder_rounded,
      label: 'الحالات',
    ),
  ),
  due(
    AppBottomNavDestination(
      icon: Icons.event_outlined,
      selectedIcon: Icons.event_rounded,
      label: 'المواعيد',
    ),
  ),
  notifications(
    AppBottomNavDestination(
      icon: Icons.notifications_none_rounded,
      selectedIcon: Icons.notifications_rounded,
      label: 'الإشعارات',
    ),
  );

  const _ShellTab(this.destination);

  final AppBottomNavDestination destination;

  /// The tabs [permissions] may see. Cases and its due-dates view go
  /// together — dropping both keeps the count even around the raised `+`.
  static List<_ShellTab> visibleFor(Permissions permissions) => [
    home,
    if (permissions.canRead(PermissionName.cases)) ...[cases, due],
    notifications,
  ];
}

class _MainShellPageState extends State<MainShellPage> {
  _ShellTab _current = _ShellTab.home;

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
    setState(() => _current = _ShellTab.notifications);
  }

  Future<void> _addCase() async {
    // The form pops `true` only after the case is actually saved. Backing out
    // of it leaves the user exactly where they were — no tab jump, and no
    // remount that would throw away the cases list's filters and scroll
    // position for nothing.
    final created = await openInLaboratory(
      context,
      () => context.push<bool>(Routes.caseFormScreen),
    );
    if (!mounted || created != true) return;
    setState(() {
      _current = _ShellTab.cases;
      _casesGeneration++;
    });
  }

  Widget _pageFor(_ShellTab tab) => switch (tab) {
    // A scanned ticket only ever opens a case, so the scanner goes with the
    // Cases permission. Built inside the permissions BlocBuilder, so it
    // follows a change.
    // The scanner is for everyone — a technician scans a restoration to reach
    // their own stage without any Cases permission. Admins set the app up and
    // skip the one-time introduction.
    _ShellTab.home => _StubTab(
      title: 'الرئيسية',
      showScanAction: true,
      introduceScanner: !getIt<SessionCubit>().state.isAdmin,
      child: const HomeBody(),
    ),
    _ShellTab.cases => CasesListPage(
      key: ValueKey(_casesGeneration),
      showAddButton: false,
    ),
    // Brings its own scaffold: the filter action sits in the app bar and
    // needs the same cubit as the list under it.
    _ShellTab.due => const CasesDueTab(),
    _ShellTab.notifications => const NotificationsTab(),
  };

  @override
  Widget build(BuildContext context) {
    // Rebuilt on permission changes: a tab the user can no longer see is not
    // just hidden but unmounted, so it stops fetching what they cannot read.
    return BlocBuilder<SessionCubit, Permissions>(
      bloc: getIt<SessionCubit>(),
      builder: (context, permissions) {
        final tabs = _ShellTab.visibleFor(permissions);
        final current = tabs.contains(_current) ? _current : _ShellTab.home;
        return _buildShell(
          context,
          tabs: tabs,
          current: current,
          // The raised `+` always starts case creation, whichever tab shows,
          // so it is gated on the Cases permission itself.
          canAddCase: permissions.canEdit(PermissionName.cases),
        );
      },
    );
  }

  Widget _buildShell(
    BuildContext context, {
    required List<_ShellTab> tabs,
    required _ShellTab current,
    required bool canAddCase,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final index = tabs.indexOf(current);

    return PopScope(
      // Back from a secondary tab returns to home instead of leaving the app,
      // which is what the hardware button means inside a tabbed shell.
      canPop: current == _ShellTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _current = _ShellTab.home);
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
            child: IndexedStack(
              index: index,
              children: [
                for (final tab in tabs)
                  KeyedSubtree(key: ValueKey(tab), child: _pageFor(tab)),
              ],
            ),
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
                  destinations: [for (final tab in tabs) tab.destination],
                  currentIndex: index,
                  onDestinationSelected: (i) {
                    if (tabs[i] == current) return;
                    setState(() => _current = tabs[i]);
                  },
                  onPrimaryAction: canAddCase ? _addCase : null,
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
    this.introduceScanner = false,
  });

  final String title;
  final Widget child;

  /// The home tab carries the scanner: it is the screen a technician opens
  /// with a tray in front of them, and scanning the ticket is how they get to
  /// the work without knowing its number.
  final bool showScanAction;

  /// Point the scanner out once, the first time this user sees it.
  final bool introduceScanner;

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
          if (showScanAction) ScannerActionButton(introduce: introduceScanner),
        ],
      ),
      body: SafeArea(child: child),
    );
  }
}
