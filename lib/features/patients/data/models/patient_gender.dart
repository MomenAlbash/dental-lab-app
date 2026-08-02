/// Gender as encoded by the API (`0` = male, `1` = female).
enum PatientGender {
  male,
  female;

  int get apiValue => index;

  String get arabicLabel => switch (this) {
    PatientGender.male => 'ذكر',
    PatientGender.female => 'أنثى',
  };

  static PatientGender? fromApi(int? value) => switch (value) {
    0 => PatientGender.male,
    1 => PatientGender.female,
    _ => null,
  };
}
