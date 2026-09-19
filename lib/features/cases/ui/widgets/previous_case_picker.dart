import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:flutter/material.dart';

/// The case a remake is redoing, chosen from what the lab already has.
typedef PreviousCase = ({String id, String label});

/// Lists the patient's earlier cases so a remake can be tied to the one it
/// corrects.
///
/// Scoped to the patient on purpose: a remake belongs to the same mouth, and
/// the whole lab's case list is not something anybody can pick out of.
Future<PreviousCase?> showPreviousCasePicker({
  required BuildContext context,
  required String patientId,
  required String patientName,
}) {
  return showGlassBottomSheet<PreviousCase>(
    context: context,
    builder: (_) =>
        _PreviousCaseSheet(patientId: patientId, patientName: patientName),
  );
}

class _PreviousCaseSheet extends StatefulWidget {
  const _PreviousCaseSheet({
    required this.patientId,
    required this.patientName,
  });

  final String patientId;
  final String patientName;

  @override
  State<_PreviousCaseSheet> createState() => _PreviousCaseSheetState();
}

class _PreviousCaseSheetState extends State<_PreviousCaseSheet> {
  List<CaseListItemModel>? _cases;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<CasesRepo>().getCases(
      filters: CaseFiltersModel(patientId: widget.patientId),
    );
    if (!mounted) return;

    result.fold(
      (failure) => setState(() => _error = failure.errorMessage),
      (cases) => setState(() => _cases = cases),
    );
  }

  static String _labelOf(CaseListItemModel item) {
    final number = item.caseNumber?.trim();
    if (number != null && number.isNotEmpty) return 'حالة رقم $number';
    final reference = item.referenceNumber?.trim();
    if (reference != null && reference.isNotEmpty) return 'مرجع $reference';
    return 'حالة بدون رقم';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final cases = _cases;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'حالات ${widget.patientName}',
            style: AppTextStyles.font18MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'اختر الحالة التي تُعاد',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (_error != null)
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.warning,
              ),
            )
          else if (cases == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (cases.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'لا توجد حالات سابقة لهذا المريض',
                textAlign: TextAlign.center,
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  final item = cases[index];
                  final label = _labelOf(item);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.history_outlined,
                      color: glass.onGlassMuted,
                    ),
                    title: Text(
                      label,
                      style: AppTextStyles.font14MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                    subtitle: Text(
                      [
                        item.stage.label,
                        if (item.createdAt != null)
                          item.createdAt!.split('T').first,
                      ].where((part) => part.isNotEmpty).join(' — '),
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                    onTap: () =>
                        Navigator.of(context).pop((id: item.id, label: label)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
