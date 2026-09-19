import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:flutter/material.dart';

/// How a tier is handed out.
enum PriceTierAudience {
  /// Every doctor on the lab's books.
  everyone,

  /// Everyone in one city.
  city,

  /// A named set.
  selected,
}

/// A city with the doctors in it, derived from the doctor list itself.
///
/// No separate cities request: a doctor already carries their city, and the
/// cities that matter here are exactly the ones somebody practises in — a city
/// with no doctors is nothing to assign a tier to.
typedef _City = ({String id, String name, List<DoctorModel> doctors});

/// Chooses a set of doctors — all of them, everyone in one city, or a named
/// selection.
///
/// Shared by every screen that hands something out per doctor: price tiers and
/// priority allowances ask the same question and must not answer it two
/// different ways. Returns the chosen doctors, or null if dismissed.
Future<List<String>?> showDoctorAudienceSheet(
  BuildContext context, {
  required List<DoctorModel> doctors,
  required String title,
  Set<String> assignedIds = const {},
}) {
  return showGlassBottomSheet<List<String>>(
    context: context,
    builder: (_) =>
        _DoctorsSheet(doctors: doctors, title: title, assignedIds: assignedIds),
  );
}

class _DoctorsSheet extends StatefulWidget {
  const _DoctorsSheet({
    required this.doctors,
    required this.title,
    required this.assignedIds,
  });

  final List<DoctorModel> doctors;
  final String title;

  final Set<String> assignedIds;

  @override
  State<_DoctorsSheet> createState() => _DoctorsSheetState();
}

class _DoctorsSheetState extends State<_DoctorsSheet> {
  late final Set<String> _selected = {...widget.assignedIds};

  late PriceTierAudience _audience =
      _selected.length == widget.doctors.length
          // Already covering the whole book: opening on "everyone" is what the
          // user last chose, as far as the API records it.
          &&
          widget.doctors.isNotEmpty
      ? PriceTierAudience.everyone
      : PriceTierAudience.selected;

  late final TextEditingController _searchController = TextEditingController()
    ..addListener(() => setState(() => _query = _searchController.text.trim()));

  String _query = '';

  /// The city whose doctors will be priced.
  String? _cityId;

  /// The cities the lab's doctors actually practise in, each with its own.
  ///
  /// Built from the doctor list rather than fetched: the doctor carries their
  /// city, and a city nobody practises in is nothing to assign a tier to.
  /// Doctors with no city recorded are left out — they cannot be reached this
  /// way, and the sheet says so rather than silently dropping them.
  List<_City> get _cities {
    final grouped = <String, ({String name, List<DoctorModel> doctors})>{};

    for (final doctor in widget.doctors) {
      final id = doctor.cityId;
      if (id == null || id.isEmpty) continue;

      grouped
          .putIfAbsent(
            id,
            () => (name: doctor.cityName ?? '—', doctors: <DoctorModel>[]),
          )
          .doctors
          .add(doctor);
    }

    final cities = [
      for (final entry in grouped.entries)
        (id: entry.key, name: entry.value.name, doctors: entry.value.doctors),
    ];
    cities.sort((a, b) => a.name.compareTo(b.name));
    return cities;
  }

  List<DoctorModel> get _cityDoctors {
    for (final city in _cities) {
      if (city.id == _cityId) return city.doctors;
    }
    return const [];
  }

  /// Doctors with no city on file, who no city choice can reach.
  int get _doctorsWithoutCity => [
    for (final doctor in widget.doctors)
      if (doctor.cityId == null || doctor.cityId!.isEmpty) doctor,
  ].length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DoctorModel> get _matches {
    if (_query.isEmpty) return widget.doctors;
    return [
      for (final doctor in widget.doctors)
        if (doctor.fullName.contains(_query) ||
            (doctor.clinicName?.contains(_query) ?? false))
          doctor,
    ];
  }

  /// What gets sent. "Everyone" is expanded to the full id list here because
  /// the API has no flag for it — see the note the sheet shows the user.
  List<String> get _result => switch (_audience) {
    PriceTierAudience.everyone => [
      for (final doctor in widget.doctors) doctor.id,
    ],
    PriceTierAudience.city => [for (final doctor in _cityDoctors) doctor.id],
    PriceTierAudience.selected => _selected.toList(),
  };

  /// Whether the sheet has an answer worth sending. No city chosen would save
  /// an empty list and quietly unassign the tier.
  bool get _canSave => switch (_audience) {
    PriceTierAudience.everyone => widget.doctors.isNotEmpty,
    PriceTierAudience.city => _cityDoctors.isNotEmpty,
    PriceTierAudience.selected => true,
  };

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final matches = _matches;
    final isEveryone = _audience == PriceTierAudience.everyone;
    final isSelected = _audience == PriceTierAudience.selected;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.cardPadding,
              AppSpacing.cardPadding,
              AppSpacing.cardPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: AppTextStyles.font18MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: 16),

                SegmentedButton<PriceTierAudience>(
                  segments: const [
                    ButtonSegment(
                      value: PriceTierAudience.everyone,
                      label: Text('الكل'),
                    ),
                    ButtonSegment(
                      value: PriceTierAudience.city,
                      label: Text('مدينة'),
                    ),
                    ButtonSegment(
                      value: PriceTierAudience.selected,
                      label: Text('أطباء محددون'),
                    ),
                  ],
                  selected: {_audience},
                  showSelectedIcon: false,
                  onSelectionChanged: (values) =>
                      setState(() => _audience = values.first),
                ),

                if (_audience == PriceTierAudience.city) ...[
                  const SizedBox(height: 16),
                  _CityPicker(
                    cities: _cities,
                    selectedId: _cityId,
                    onChanged: (id) => setState(() => _cityId = id),
                  ),
                  const SizedBox(height: 12),
                  _CityResult(
                    doctors: _cityDoctors,
                    hasChosen: _cityId != null,
                    doctorsWithoutCity: _doctorsWithoutCity,
                  ),
                ],

                if (isEveryone) ...[
                  const SizedBox(height: 12),
                  // Said plainly because the API cannot do better: there is no
                  // "applies to everyone" flag, only a list of doctors. A tier
                  // saved for everyone today does not pick up a doctor
                  // registered tomorrow, and implying otherwise would leave
                  // that doctor silently unpriced.
                  _Note(
                    text:
                        'سيتم إسناد الشريحة إلى ${widget.doctors.length} طبيب '
                        'مسجّلين حالياً. الطبيب الذي يُسجَّل لاحقاً لن يُضاف '
                        'تلقائياً — أعد الإسناد بعد إضافته.',
                  ),
                ],

                if (isSelected) ...[
                  const SizedBox(height: 16),
                  AppTextFormField(
                    controller: _searchController,
                    hintText: 'ابحث باسم الطبيب أو العيادة',
                    prefixIcon: Icon(Icons.search, color: glass.onGlassMuted),
                    validator: (_) => null,
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),

          if (isSelected)
            Flexible(
              child: matches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Text(
                        _query.isEmpty ? 'لا يوجد أطباء' : 'لا نتائج',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.font14RegularSecondary.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.cardPadding,
                      ),
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final doctor = matches[index];

                        return CheckboxListTile(
                          value: _selected.contains(doctor.id),
                          onChanged: (_) => setState(
                            () => _selected.contains(doctor.id)
                                ? _selected.remove(doctor.id)
                                : _selected.add(doctor.id),
                          ),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            doctor.fullName.isEmpty ? '—' : doctor.fullName,
                            style: AppTextStyles.font14RegularSecondary
                                .copyWith(color: glass.onGlass),
                          ),
                          subtitle: (doctor.clinicName?.isNotEmpty ?? false)
                              ? Text(
                                  doctor.clinicName!,
                                  style: AppTextStyles.font12RegularHint
                                      .copyWith(color: glass.onGlassMuted),
                                )
                              : null,
                        );
                      },
                    ),
            ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: CustomButtonWidget(
              buttonText: switch (_audience) {
                PriceTierAudience.everyone =>
                  'إسناد للكل (${widget.doctors.length})',
                PriceTierAudience.city =>
                  'إسناد للمدينة (${_cityDoctors.length})',
                PriceTierAudience.selected => 'حفظ (${_selected.length})',
              },
              // Disabled rather than saving an empty list: no city chosen
              // would unassign the tier.
              onPressed: _canSave
                  ? () => Navigator.of(context).pop(_result)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CityPicker extends StatelessWidget {
  const _CityPicker({
    required this.cities,
    required this.selectedId,
    required this.onChanged,
  });

  final List<_City> cities;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    if (cities.isEmpty) {
      return Text(
        'لا توجد مدينة مسجّلة على أي طبيب',
        style: AppTextStyles.font12RegularHint.copyWith(
          color: glass.onGlassMuted,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final city in cities)
          ChoiceChip(
            // The count is the point: it is how many doctors this choice
            // actually prices.
            label: Text('${city.name} (${city.doctors.length})'),
            selected: selectedId == city.id,
            onSelected: (_) => onChanged(city.id),
          ),
      ],
    );
  }
}

/// Who the chosen city turned out to contain.
///
/// Named rather than counted: "١٢ طبيب" is not something a user can check
/// before committing a price list to them.
class _CityResult extends StatelessWidget {
  const _CityResult({
    required this.doctors,
    required this.hasChosen,
    required this.doctorsWithoutCity,
  });

  final List<DoctorModel> doctors;
  final bool hasChosen;
  final int doctorsWithoutCity;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    if (!hasChosen) {
      return Text(
        'اختر مدينة لعرض أطبائها',
        style: AppTextStyles.font12RegularHint.copyWith(
          color: glass.onGlassMuted,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final doctor in doctors)
              Chip(
                label: Text(doctor.fullName.isEmpty ? '—' : doctor.fullName),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // The same snapshot caveat as "everyone", and for the same reason: the
        // API stores a doctor list, not a city.
        const _Note(
          text:
              'يُسنَد أطباء المدينة الحاليون فقط. الطبيب الذي يُسجَّل فيها '
              'لاحقاً لن يُضاف تلقائياً.',
        ),
        // Doctors with no city cannot be reached by any city choice. Left
        // unsaid, they would simply never get priced and nobody would know.
        if (doctorsWithoutCity > 0) ...[
          const SizedBox(height: 8),
          Text(
            '$doctorsWithoutCity طبيب بلا مدينة مسجّلة — لن يشملهم أي اختيار '
            'مدينة، أسندهم من "أطباء محددون".',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.warning,
            ),
          ),
        ],
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: glass.accentSurface,
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
