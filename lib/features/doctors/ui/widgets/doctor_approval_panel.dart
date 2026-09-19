import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/zones/logic/zones/zones_cubit.dart';
import 'package:dental_lab_app/features/zones/logic/zones/zones_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the user chose in the approve dialog: link the doctor to an existing
/// clinic (or create the one they asked for — exactly one of the clinic pair
/// is set), and optionally assign that clinic to a zone the same way (the
/// zone pair may both be null — a zone is not mandatory).
typedef ApprovalChoice = ({
  String? clinicId,
  String? newClinicName,
  String? zoneId,
  String? newZoneName,
});

/// The review panel on a doctor's detail screen.
///
/// Doctors can register themselves now, so a record can arrive that the lab
/// has not agreed to yet. Pending shows the decision; rejected shows why. An
/// approved doctor is the ordinary case and renders nothing at all, so the
/// screen is unchanged for the records the lab created itself.
class DoctorApprovalPanel extends StatelessWidget {
  const DoctorApprovalPanel({
    super.key,
    required this.doctor,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  final DoctorModel doctor;
  final bool isBusy;
  final ValueChanged<ApprovalChoice> onApprove;
  final ValueChanged<String> onReject;

  @override
  Widget build(BuildContext context) {
    return switch (doctor.approvalStatus) {
      DoctorApprovalStatus.pending => _PendingPanel(
        doctor: doctor,
        isBusy: isBusy,
        onApprove: onApprove,
        onReject: onReject,
      ),
      DoctorApprovalStatus.rejected => _RejectedNotice(doctor: doctor),
      DoctorApprovalStatus.approved => const SizedBox.shrink(),
    };
  }
}

class _PendingPanel extends StatelessWidget {
  const _PendingPanel({
    required this.doctor,
    required this.isBusy,
    required this.onApprove,
    required this.onReject,
  });

  final DoctorModel doctor;
  final bool isBusy;
  final ValueChanged<ApprovalChoice> onApprove;
  final ValueChanged<String> onReject;

  Future<void> _askApprove(BuildContext context) async {
    final choice = await showDialog<ApprovalChoice>(
      context: context,
      builder: (_) => MultiBlocProvider(
        // A dialog is its own route, so it cannot reach the page's providers.
        providers: [
          BlocProvider(create: (_) => getIt<ClinicsCubit>()..getClinics()),
          BlocProvider(create: (_) => getIt<ZonesCubit>()..getZones()),
        ],
        child: _ApproveDialog(requestedClinicName: doctor.requestedClinicName),
      ),
    );

    if (choice != null) onApprove(choice);
  }

  Future<void> _askReject(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectDialog(),
    );

    if (reason != null) onReject(reason);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final requested = doctor.requestedClinicName?.trim() ?? '';

    return _Panel(
      color: glass.warning,
      icon: Icons.how_to_reg_outlined,
      title: 'تسجيل بانتظار المراجعة',
      children: [
        Text(
          'سجّل هذا الدكتور نفسه ولم تتم الموافقة عليه بعد.',
          style: AppTextStyles.font14RegularSecondary.copyWith(
            color: glass.onGlassMuted,
          ),
        ),
        if (requested.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.local_hospital_outlined,
                size: 16,
                color: glass.onGlassMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'العيادة المطلوبة: $requested',
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isBusy ? null : () => _askApprove(context),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('قبول'),
                style: FilledButton.styleFrom(
                  backgroundColor: glass.success,
                  minimumSize: const Size.fromHeight(46),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isBusy ? null : () => _askReject(context),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('رفض'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: glass.error,
                  side: BorderSide(color: glass.error.withValues(alpha: 0.6)),
                  minimumSize: const Size.fromHeight(46),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RejectedNotice extends StatelessWidget {
  const _RejectedNotice({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final reason = doctor.rejectionReason?.trim() ?? '';

    return _Panel(
      color: glass.error,
      icon: Icons.block_outlined,
      title: 'تم رفض التسجيل',
      children: [
        Text(
          reason.isEmpty ? 'لم يُسجَّل سبب للرفض.' : 'السبب: $reason',
          style: AppTextStyles.font14RegularSecondary.copyWith(
            color: glass.onGlassMuted,
          ),
        ),
      ],
    );
  }
}

/// The tinted card both states share.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.color,
    required this.icon,
    required this.title,
    required this.children,
  });

  final Color color;
  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.font16MediumText.copyWith(color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

/// Picks what clinic the doctor is attached to on approval.
///
/// A clinic is mandatory here, the same way it is on the doctor form: an
/// approved doctor with no clinic cannot be reached through the clinic
/// listings the rest of the app is organised around. So the choice is only
/// *which* clinic — link an existing one, or create the one they asked for.
class _ApproveDialog extends StatefulWidget {
  const _ApproveDialog({this.requestedClinicName});

  final String? requestedClinicName;

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

enum _ClinicChoice { existing, create }

enum _ZoneChoice { unchanged, existing, create }

class _ApproveDialogState extends State<_ApproveDialog> {
  late final String _requested = widget.requestedClinicName?.trim() ?? '';

  /// Creating the clinic the doctor named is the expected path when they named
  /// one; otherwise there is nothing to create, so start from the list.
  late _ClinicChoice _choice = _requested.isEmpty
      ? _ClinicChoice.existing
      : _ClinicChoice.create;

  String? _clinicId;
  String? _error;

  // A zone is not mandatory the way a clinic is — "unchanged" is the default
  // and the ordinary case for a lab that has not started zoning its clinics.
  _ZoneChoice _zoneChoice = _ZoneChoice.unchanged;
  String? _zoneId;
  final _newZoneNameController = TextEditingController();

  @override
  void dispose() {
    _newZoneNameController.dispose();
    super.dispose();
  }

  void _confirm() {
    final String? clinicId;
    final String? newClinicName;
    switch (_choice) {
      case _ClinicChoice.existing:
        if (_clinicId == null) {
          setState(() => _error = 'اختر العيادة أولاً');
          return;
        }
        clinicId = _clinicId;
        newClinicName = null;
      case _ClinicChoice.create:
        clinicId = null;
        newClinicName = _requested;
    }

    final String? zoneId;
    final String? newZoneName;
    switch (_zoneChoice) {
      case _ZoneChoice.unchanged:
        zoneId = null;
        newZoneName = null;
      case _ZoneChoice.existing:
        if (_zoneId == null) {
          setState(() => _error = 'اختر المنطقة أولاً');
          return;
        }
        zoneId = _zoneId;
        newZoneName = null;
      case _ZoneChoice.create:
        final name = _newZoneNameController.text.trim();
        if (name.isEmpty) {
          setState(() => _error = 'اكتب اسم المنطقة');
          return;
        }
        zoneId = null;
        newZoneName = name;
    }

    Navigator.of(context).pop((
      clinicId: clinicId,
      newClinicName: newClinicName,
      zoneId: zoneId,
      newZoneName: newZoneName,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return AlertDialog(
      title: Text('قبول الدكتور', style: AppTextStyles.font18MediumText),
      // A bounded width is required because AlertDialog measures its content's
      // intrinsic width, which the clinic list cannot provide.
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'لا يمكن قبول الدكتور دون ربطه بعيادة:',
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RadioGroup<_ClinicChoice>(
                groupValue: _choice,
                onChanged: (value) => setState(() {
                  _choice = value!;
                  _error = null;
                }),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_requested.isNotEmpty)
                      RadioListTile<_ClinicChoice>(
                        value: _ClinicChoice.create,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'إنشاء العيادة المطلوبة: $_requested',
                          style: AppTextStyles.font14MediumText,
                        ),
                      ),
                    RadioListTile<_ClinicChoice>(
                      value: _ClinicChoice.existing,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'اختيار عيادة موجودة',
                        style: AppTextStyles.font14MediumText,
                      ),
                    ),
                  ],
                ),
              ),
              if (_choice == _ClinicChoice.existing)
                BlocBuilder<ClinicsCubit, ClinicsState>(
                  builder: (context, state) {
                    final clinics = state is ClinicsLoaded
                        ? state.clinics
                        : null;
                    return DropdownButtonFormField<String>(
                      initialValue: _clinicId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: state is ClinicsLoading
                            ? 'جارٍ تحميل العيادات...'
                            : 'اختر العيادة',
                      ),
                      items: clinics
                          ?.map(
                            (clinic) => DropdownMenuItem(
                              value: clinic.id,
                              child: Text(clinic.name),
                            ),
                          )
                          .toList(),
                      onChanged: clinics == null
                          ? null
                          : (value) => setState(() {
                              _clinicId = value;
                              _error = null;
                            }),
                    );
                  },
                ),

              // Optional: assigning the clinic to a zone. Left on "بدون
              // تغيير" by default — a zone is not mandatory the way a
              // clinic is.
              const SizedBox(height: AppSpacing.lg),
              Text(
                'منطقة العيادة (اختياري):',
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RadioGroup<_ZoneChoice>(
                groupValue: _zoneChoice,
                onChanged: (value) => setState(() {
                  _zoneChoice = value!;
                  _error = null;
                }),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RadioListTile<_ZoneChoice>(
                      value: _ZoneChoice.unchanged,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'بدون تغيير',
                        style: AppTextStyles.font14MediumText,
                      ),
                    ),
                    RadioListTile<_ZoneChoice>(
                      value: _ZoneChoice.existing,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'اختيار منطقة موجودة',
                        style: AppTextStyles.font14MediumText,
                      ),
                    ),
                    RadioListTile<_ZoneChoice>(
                      value: _ZoneChoice.create,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'إنشاء منطقة جديدة',
                        style: AppTextStyles.font14MediumText,
                      ),
                    ),
                  ],
                ),
              ),
              if (_zoneChoice == _ZoneChoice.existing)
                BlocBuilder<ZonesCubit, ZonesState>(
                  builder: (context, state) {
                    final zones = state is ZonesLoaded ? state.zones : null;
                    return DropdownButtonFormField<String>(
                      initialValue: _zoneId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: state is ZonesLoading
                            ? 'جارٍ تحميل المناطق...'
                            : 'اختر المنطقة',
                      ),
                      items: zones
                          ?.map(
                            (zone) => DropdownMenuItem(
                              value: zone.id,
                              child: Text(
                                (zone.nameAr?.trim().isNotEmpty ?? false)
                                    ? zone.nameAr!.trim()
                                    : (zone.name ?? '—'),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: zones == null
                          ? null
                          : (value) => setState(() {
                              _zoneId = value;
                              _error = null;
                            }),
                    );
                  },
                )
              else if (_zoneChoice == _ZoneChoice.create)
                AppTextFormField(
                  controller: _newZoneNameController,
                  hintText: 'اسم المنطقة',
                  validator: (_) => null,
                ),

              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _confirm, child: const Text('قبول')),
      ],
    );
  }
}

/// Collects the rejection reason, which the API requires (1..1000 chars).
class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reasonController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'اكتب سبب الرفض');
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('رفض التسجيل', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'سيظهر السبب على صفحة الدكتور.',
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: context.glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextFormField(
              controller: _reasonController,
              hintText: 'سبب الرفض',
              maxLines: 3,
              // The API caps the reason at 1000 characters.
              inputFormatters: [LengthLimitingTextInputFormatter(1000)],
              validator: (_) => null,
            ),
            if (_error != null)
              Text(
                _error!,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: context.glass.error,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: _confirm,
          child: Text(
            'رفض',
            style: AppTextStyles.font14MediumText.copyWith(
              color: context.glass.error,
            ),
          ),
        ),
      ],
    );
  }
}
