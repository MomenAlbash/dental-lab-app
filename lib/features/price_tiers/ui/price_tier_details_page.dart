import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_doctors/price_tier_doctors_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_doctors/price_tier_doctors_state.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_prices/price_tier_prices_cubit.dart';
import 'package:dental_lab_app/core/widgets/doctor_audience_sheet.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_prices/price_tier_prices_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Formats a price keeping decimals when present, e.g. 12.5 -> "12.5",
/// 12.0 -> "12" (toStringAsFixed(0) alone would round 12.5 to "13").
String _formatPrice(double price) {
  if (price <= 0) return '';
  final text = price.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Shows a price tier's info plus each restoration type's price, edited
/// one at a time via a dialog instead of a bulk-edit page.
class PriceTierDetailsPage extends StatelessWidget {
  const PriceTierDetailsPage({super.key, required this.priceTier});

  final PriceTierModel priceTier;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<PriceTierPricesCubit>()..load(priceTier.id),
        ),
        BlocProvider(
          create: (_) => getIt<PriceTierDoctorsCubit>()..load(priceTier.id),
        ),
      ],
      child: _PriceTierDetailsView(priceTier: priceTier),
    );
  }
}

class _PriceTierDetailsView extends StatelessWidget {
  const _PriceTierDetailsView({required this.priceTier});

  final PriceTierModel priceTier;

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          priceTier.name ?? '—',
          style: AppTextStyles.font18MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<PriceTierPricesCubit, PriceTierPricesState>(
          listener: (context, state) {
            switch (state) {
              case PriceTierPricesActionSuccess(:final message):
                showToast(message: message, state: ToastState.success);
              case PriceTierPricesActionError(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! PriceTierPricesActionError &&
              current is! PriceTierPricesActionSuccess,
          builder: (context, state) {
            return switch (state) {
              PriceTierPricesLoaded(:final items) => _DetailsList(
                priceTier: priceTier,
                items: items,
              ),
              PriceTierPricesError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: context.glass.onGlassMuted,
                    ),
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

/// The doctors billed at this tier, and the button that changes them.
class _DoctorsSection extends StatefulWidget {
  const _DoctorsSection();

  @override
  State<_DoctorsSection> createState() => _DoctorsSectionState();
}

class _DoctorsSectionState extends State<_DoctorsSection> {
  /// The lab's whole book, loaded once for the picker. The cities come out of
  /// this same list — a doctor carries their own city, so grouping needs no
  /// second request.
  List<DoctorModel> _allDoctors = const [];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final result = await getIt<DoctorsRepo>().getDoctors();
    if (!mounted) return;

    // A failure here is not worth an error screen: the assigned list still
    // reads, and only the picker is poorer for it.
    result.fold((_) {}, (doctors) {
      setState(() {
        _allDoctors = [
          for (final doctor in doctors)
            if (doctor.isActive) doctor,
        ];
      });
    });
  }

  Future<void> _assign(List<PriceTierDoctorModel> assigned) async {
    final cubit = context.read<PriceTierDoctorsCubit>();

    final result = await showDoctorAudienceSheet(
      context,
      doctors: _allDoctors,
      title: 'إسناد الشريحة السعرية',
      assignedIds: {for (final doctor in assigned) doctor.id},
    );
    if (result == null) return;

    await cubit.setDoctors(result);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return BlocConsumer<PriceTierDoctorsCubit, PriceTierDoctorsState>(
      listener: (context, state) {
        if (state is PriceTierDoctorsMessage) {
          showToast(
            message: state.message,
            state: state.isError ? ToastState.error : ToastState.success,
          );
        }
      },
      buildWhen: (_, current) => current is! PriceTierDoctorsMessage,
      builder: (context, state) {
        final loaded = state is PriceTierDoctorsLoaded ? state : null;
        final doctors = loaded?.doctors ?? const <PriceTierDoctorModel>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassSectionTitle('الأطباء', count: doctors.length),
            const SizedBox(height: 8),

            if (state is PriceTierDoctorsError)
              Text(
                state.message,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.error,
                ),
              )
            else if (doctors.isEmpty)
              Text(
                'لم تُسنَد هذه الشريحة إلى أي طبيب — لن تُطبَّق أسعارها على أحد.',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.warning,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final doctor in doctors)
                    Chip(
                      label: Text(
                        doctor.number == null
                            ? doctor.displayName
                            : '${doctor.number} · ${doctor.displayName}',
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: (loaded?.isBusy ?? false)
                    ? null
                    : () => _assign(doctors),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('إسناد الشريحة'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailsList extends StatelessWidget {
  const _DetailsList({required this.priceTier, required this.items});

  final PriceTierModel priceTier;
  final List<PriceTierPriceItem> items;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PriceTierPricesCubit>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final contentWidth = isWide ? 700.0 : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 16,
                vertical: 16,
              ),
              children: [
                _DetailsHeader(priceTier: priceTier),
                const SizedBox(height: 16),
                // Who pays these prices comes before the prices themselves: a
                // tier assigned to nobody is a price list that bills no one,
                // and it looks identical to a working one until you ask.
                const _DoctorsSection(),
                const SizedBox(height: 16),
                const GlassSectionTitle('الأسعار'),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'لا يوجد تعويضات لتسعيرها',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.font14RegularSecondary.copyWith(
                        color: context.glass.onGlassMuted,
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < items.length; i++)
                    _PriceRow(
                      item: items[i],
                      onEdit: () => showDialog<void>(
                        context: context,
                        builder: (_) => _EditPriceDialog(
                          item: items[i],
                          onSave: (price) {
                            cubit.setPrice(i, price);
                            cubit.save();
                          },
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({required this.priceTier});

  final PriceTierModel priceTier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: context.glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: context.glass.strokeColor),
        boxShadow: context.glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (priceTier.description != null &&
              priceTier.description!.isNotEmpty) ...[
            Text(
              priceTier.description!,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: context.glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              _Badge(
                label: priceTier.isActive ? 'مفعّلة' : 'موقوفة',
                color: priceTier.isActive
                    ? context.glass.success
                    : context.glass.onGlassMuted,
              ),
              const SizedBox(width: 6),
              _Badge(
                label:
                    '${priceTier.pricedRestorationCount}/${priceTier.totalRestorationTypeCount} مسعّرة',
                color: context.glass.info,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.item, required this.onEdit});

  final PriceTierPriceItem item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: context.glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: context.glass.strokeColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.restorationTypeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font14MediumText.copyWith(
                color: context.glass.onGlass,
              ),
            ),
          ),
          Text(
            item.price > 0 ? _formatPrice(item.price) : '—',
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: context.glass.onGlassMuted,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'تعديل',
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.edit_outlined, color: context.glass.onGlassMuted),
          ),
        ],
      ),
    );
  }
}

class _EditPriceDialog extends StatefulWidget {
  const _EditPriceDialog({required this.item, required this.onSave});

  final PriceTierPriceItem item;
  final ValueChanged<double> onSave;

  @override
  State<_EditPriceDialog> createState() => _EditPriceDialogState();
}

class _EditPriceDialogState extends State<_EditPriceDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.item.price > 0 ? _formatPrice(widget.item.price) : '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تعديل سعر "${widget.item.restorationTypeName}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'السعر الحالي: ${widget.item.price > 0 ? _formatPrice(widget.item.price) : '—'}',
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: context.glass.onGlassMuted,
            ),
          ),
          const SizedBox(height: 12),
          AppTextFormField(
            controller: _controller,
            hintText: 'السعر الجديد',
            validator: (_) => null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () {
            var text = _controller.text.trim();
            if (text.endsWith('.')) {
              text = text.substring(0, text.length - 1);
            }
            final price = text.isEmpty
                ? 0.0
                : double.tryParse(text) ?? widget.item.price;
            widget.onSave(price);
            Navigator.of(context).pop();
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
