import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:flutter/material.dart';

/// Collapsing brand header for the employee detail screen — mirrors
/// [DoctorSliverHeader]'s layout and motion so both screens read as one
/// product, minus the active/paused status pill employees don't have.
class EmployeeSliverHeader extends StatelessWidget {
  const EmployeeSliverHeader({
    super.key,
    required this.employee,
    required this.onEdit,
  });

  final EmployeeModel employee;
  final VoidCallback onEdit;

  static const double expandedHeight = 240;

  @override
  Widget build(BuildContext context) {
    final name = employee.fullName.isEmpty ? '—' : employee.fullName;

    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.glassLg),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'تعديل',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      // `FlexibleSpaceBar.title` is deliberately not used: it stays on screen
      // while expanded as well, which rendered the name twice. Instead the two
      // placements are cross-faded by scroll progress, and only the one with
      // non-zero opacity is built.
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final topInset = MediaQuery.paddingOf(context).top;
          final maxExtent = expandedHeight + topInset;
          final minExtent = kToolbarHeight + topInset;

          final collapsed =
              ((maxExtent - constraints.maxHeight) / (maxExtent - minExtent))
                  .clamp(0.0, 1.0);

          final panelOpacity = (1 - collapsed * 1.8).clamp(0.0, 1.0);
          final titleOpacity = ((collapsed - 0.65) / 0.35).clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              _HeaderBackdrop(
                child: panelOpacity == 0
                    ? const SizedBox.shrink()
                    : Opacity(
                        opacity: panelOpacity,
                        child: ClipRect(
                          child: OverflowBox(
                            alignment: Alignment.topCenter,
                            minHeight: maxExtent,
                            maxHeight: maxExtent,
                            child: _HeaderPanel(employee: employee, name: name),
                          ),
                        ),
                      ),
              ),
              if (titleOpacity > 0)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: topInset),
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 52),
                        child: Opacity(
                          opacity: titleOpacity,
                          child: _CompactIdentity(
                            employee: employee,
                            name: name,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderBackdrop extends StatelessWidget {
  const _HeaderBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.glass.brandGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(top: -60, right: -40, child: _Blob(size: 200)),
          const Positioned(bottom: -70, left: -50, child: _Blob(size: 180)),
          child,
        ],
      ),
    );
  }
}

class _CompactIdentity extends StatelessWidget {
  const _CompactIdentity({required this.employee, required this.name});

  final EmployeeModel employee;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _Avatar(employee: employee, size: 34, showHero: false),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font14MediumText.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Identity block: photo, then name — no status pill, unlike the doctor
/// header, since an employee has no active/paused state.
class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({required this.employee, required this.name});

  final EmployeeModel employee;
  final String name;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, kToolbarHeight - 8, 24, 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Avatar(employee: employee),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.font20BoldText.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            if ((employee.code ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _CodePill(code: employee.code!.trim()),
            ],
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.employee, this.size = 88, this.showHero = true});

  final EmployeeModel employee;
  final double size;

  /// Only the expanded panel's avatar carries the hero tag — two heroes with
  /// the same tag in one tree is an error, and both can be mounted for a
  /// frame during the collapse cross-fade.
  final bool showHero;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(employee.imagePath);

    final fallback = Center(
      child: Text(
        employee.initials,
        style: AppTextStyles.font24BoldText.copyWith(
          color: Colors.white,
          fontSize: size * 0.34,
        ),
      ),
    );

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: size >= 60 ? 2 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: size >= 60 ? 22 : 8,
            offset: Offset(0, size >= 60 ? 8 : 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? fallback
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );

    if (!showHero) return avatar;
    return Hero(tag: 'employee-avatar-${employee.id}', child: avatar);
  }
}

class _CodePill extends StatelessWidget {
  const _CodePill({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        code,
        style: AppTextStyles.font12RegularHint.copyWith(color: Colors.white),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.20),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
