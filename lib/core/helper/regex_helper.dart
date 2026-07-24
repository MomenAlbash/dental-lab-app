class RegexHelper {
  RegexHelper._();

  static final RegExp email = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  static bool isValidEmail(String? value) {
    return value != null && value.isNotEmpty && email.hasMatch(value);
  }
}
