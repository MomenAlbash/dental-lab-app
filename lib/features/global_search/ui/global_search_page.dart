import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_card.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/laboratory_badge.dart';
import 'package:dental_lab_app/features/global_search/data/recent_items_repo.dart';
import 'package:dental_lab_app/features/global_search/logic/global_search_cubit.dart';
import 'package:dental_lab_app/features/global_search/logic/global_search_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Finds a case, a patient or a doctor from one box — searched on the server,
/// across everything in view, not just what a list happens to have loaded.
class GlobalSearchPage extends StatelessWidget {
  const GlobalSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<GlobalSearchCubit>()..loadRecent(),
      child: const _GlobalSearchView(),
    );
  }
}

class _GlobalSearchView extends StatefulWidget {
  const _GlobalSearchView();

  @override
  State<_GlobalSearchView> createState() => _GlobalSearchViewState();
}

class _GlobalSearchViewState extends State<_GlobalSearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final cubit = context.read<GlobalSearchCubit>();

    return GlassScaffold(
      appBar: GlassAppBar(
        centerTitle: false,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (text) {
            setState(() {}); // shows or hides the clear button
            cubit.onQueryChanged(text);
          },
          onSubmitted: (text) {
            final query = text.trim();
            if (query.length >= GlobalSearchCubit.minLength) {
              cubit.search(query);
            }
          },
          style: AppTextStyles.font16MediumText.copyWith(color: glass.onGlass),
          decoration: InputDecoration(
            hintText: 'رقم حالة، اسم مريض أو دكتور',
            border: InputBorder.none,
            hintStyle: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: 'مسح',
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                setState(() {});
                cubit.onQueryChanged('');
              },
            ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<GlobalSearchCubit, GlobalSearchState>(
          builder: (context, state) {
            if (state.isIdle && state.recent.isNotEmpty) {
              return _RecentList(items: state.recent);
            }
            if (state.isIdle) {
              return _Hint(
                text:
                    'اكتب حرفين على الأقل — يُبحث في الحالات والمرضى والدكاترة معاً',
              );
            }
            if (state.isEmpty) {
              return _Hint(text: 'لا نتائج لـ "${state.query}"');
            }
            return Center(
              // A list to read, not a grid to scan: kept to a reading width.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  children: [
                    _Section(
                      title: 'الحالات',
                      icon: Icons.folder_outlined,
                      section: state.cases,
                      rowBuilder: (c) => _ResultRow(
                        title: c.caseNumber?.isNotEmpty ?? false
                            ? 'حالة ${c.caseNumber}'
                            : 'حالة بدون رقم',
                        subtitle: [
                          c.patientName,
                          c.doctorName,
                          c.stageLabel,
                        ].where((v) => v?.isNotEmpty ?? false).join(' · '),
                        laboratoryId: c.laboratoryId ?? c.laboratory?.id,
                        onTap: () => _open(
                          context,
                          RecentItem(
                            kind: RecentItemKind.caseItem,
                            id: c.id,
                            title: c.caseNumber?.isNotEmpty ?? false
                                ? 'حالة ${c.caseNumber}'
                                : 'حالة بدون رقم',
                            subtitle: c.patientName ?? '',
                          ),
                        ),
                      ),
                    ),
                    _Section(
                      title: 'المرضى',
                      icon: Icons.person_outline,
                      section: state.patients,
                      rowBuilder: (p) => _ResultRow(
                        title: p.fullName.isEmpty ? '—' : p.fullName,
                        subtitle: [
                          p.doctorName,
                          p.phoneNumber,
                        ].where((v) => v?.isNotEmpty ?? false).join(' · '),
                        laboratoryId: p.laboratoryId,
                        onTap: () => _open(
                          context,
                          RecentItem(
                            kind: RecentItemKind.patient,
                            id: p.id,
                            title: p.fullName,
                            subtitle: p.doctorName ?? '',
                          ),
                        ),
                      ),
                    ),
                    _Section(
                      title: 'الدكاترة',
                      icon: Icons.medical_services_outlined,
                      section: state.doctors,
                      rowBuilder: (d) => _ResultRow(
                        title: d.fullName.isEmpty ? '—' : d.fullName,
                        subtitle: [
                          d.clinicName,
                          d.phoneNumber,
                        ].where((v) => v?.isNotEmpty ?? false).join(' · '),
                        laboratoryId: d.laboratoryId,
                        onTap: () => _open(
                          context,
                          RecentItem(
                            kind: RecentItemKind.doctor,
                            id: d.id,
                            title: d.fullName,
                            subtitle: d.clinicName ?? '',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Section<T> extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.section,
    required this.rowBuilder,
  });

  final String title;
  final IconData icon;
  final SearchSection<T> section;
  final Widget Function(T item) rowBuilder;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final muted = AppTextStyles.font12RegularHint.copyWith(
      color: glass.onGlassMuted,
    );

    // A section that found nothing takes no room — the ones that did are
    // what the user came for.
    if (section case SectionResults(:final items) when items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: glass.onGlassMuted),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.font14MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          switch (section) {
            SectionLoading() => const LinearProgressIndicator(),
            SectionError(:final message) => Text(message, style: muted),
            SectionResults(:final items, :final hasMore) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items) rowBuilder(item),
                if (hasMore) Text('نتائج أكثر — اكتب تفاصيل أدق', style: muted),
              ],
            ),
            SectionIdle() => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.title,
    required this.subtitle,
    required this.laboratoryId,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String? laboratoryId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
              ],
            ),
          ),
          LaboratoryBadge(laboratoryId: laboratoryId),
          Icon(Icons.chevron_left, color: glass.onGlassMuted),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
}

/// Remembers [item] as recently opened, then opens it.
void _open(BuildContext context, RecentItem item) {
  context.read<GlobalSearchCubit>().remember(item);
  final route = switch (item.kind) {
    RecentItemKind.caseItem => Routes.caseDetailScreen,
    RecentItemKind.patient => Routes.patientDetailScreen,
    RecentItemKind.doctor => Routes.doctorDetailScreen,
  };
  context.push(route, extra: item.id);
}

/// What was opened before — shown while nothing is typed, since the record
/// looked at a moment ago is the one most often wanted again.
class _RecentList extends StatelessWidget {
  const _RecentList({required this.items});

  final List<RecentItem> items;

  static IconData _iconOf(RecentItemKind kind) => switch (kind) {
    RecentItemKind.caseItem => Icons.folder_outlined,
    RecentItemKind.patient => Icons.person_outline,
    RecentItemKind.doctor => Icons.medical_services_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screen),
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 18, color: glass.onGlassMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'آخر ما فتحته',
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: context.read<GlobalSearchCubit>().clearRecent,
                  child: const Text('مسح'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final item in items)
              GlassCard(
                onTap: () => _open(context, item),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(_iconOf(item.kind), color: glass.onGlassMuted),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title.isEmpty ? '—' : item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.font14MediumText.copyWith(
                              color: glass.onGlass,
                            ),
                          ),
                          if (item.subtitle.isNotEmpty)
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.font12RegularHint.copyWith(
                                color: glass.onGlassMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
