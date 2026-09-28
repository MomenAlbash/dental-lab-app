import 'package:flutter/material.dart';

/// A record's page split into "details" and "cases", under its own
/// collapsing header — the doctor's and the patient's pages alike.
///
/// The tabs are pinned under the header ([header] receives the tab bar to put
/// in its `bottom`), and each tab scrolls on its own beneath it.
class DetailWithCasesTabs extends StatelessWidget {
  const DetailWithCasesTabs({
    super.key,
    required this.header,
    required this.details,
    required this.cases,
    this.storageKey = 'details',
    this.extraTabs = const [],
  });

  /// The page's collapsing `SliverAppBar`, given the tab bar as its bottom.
  final Widget Function(PreferredSizeWidget tabBar) header;

  /// The first tab's content — what the page showed before it had tabs.
  final Widget details;

  /// The second tab — a cases list, only built once the tab is opened.
  final Widget cases;

  /// Keeps the details tab's scroll position when switching back to it.
  final String storageKey;

  /// Further tabs after "cases" — each built only once opened, and pushed
  /// below the header the same way.
  final List<({String label, Widget child})> extraTabs;

  static Widget _belowHeader(Widget child) => _BelowHeader(child: child);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2 + extraTabs.length,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // Absorbs the pinned header's height, so each tab's content starts
          // below it instead of scrolling under it.
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: header(
              TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  const Tab(text: 'التفاصيل'),
                  const Tab(text: 'الحالات'),
                  for (final tab in extraTabs) Tab(text: tab.label),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            Builder(
              builder: (context) => CustomScrollView(
                key: PageStorageKey(storageKey),
                slivers: [
                  SliverOverlapInjector(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                      context,
                    ),
                  ),
                  SliverToBoxAdapter(child: details),
                ],
              ),
            ),
            _belowHeader(cases),
            for (final tab in extraTabs) _belowHeader(tab.child),
          ],
        ),
      ),
    );
  }
}

/// A tab that scrolls with its own widgets, which take no sliver injector —
/// it is pushed below the header by the absorbed height instead.
///
/// The handle announces a new height in the middle of layout, where a rebuild
/// is not allowed; so the change is taken up after the frame rather than on
/// the spot.
class _BelowHeader extends StatefulWidget {
  const _BelowHeader({required this.child});

  final Widget child;

  @override
  State<_BelowHeader> createState() => _BelowHeaderState();
}

class _BelowHeaderState extends State<_BelowHeader> {
  SliverOverlapAbsorberHandle? _handle;
  double _top = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final handle = NestedScrollView.sliverOverlapAbsorberHandleFor(context);
    if (!identical(handle, _handle)) {
      _handle?.removeListener(_onExtentChanged);
      _handle = handle..addListener(_onExtentChanged);
      _top = handle.layoutExtent ?? 0;
    }
  }

  void _onExtentChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final top = _handle?.layoutExtent ?? 0;
      if (mounted && top != _top) setState(() => _top = top);
    });
  }

  @override
  void dispose() {
    _handle?.removeListener(_onExtentChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: _top),
      child: widget.child,
    );
  }
}
