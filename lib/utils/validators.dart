class Validators {
  const Validators._();

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : 'Enter a valid email address';
  }

  static String? password(String? value) => (value?.length ?? 0) < 8
      ? 'Password must be at least 8 characters'
      : null;

  static String? requiredPassword(String? value) =>
      (value?.isEmpty ?? true) ? 'Enter your password' : null;

  static String? name(String? value) =>
      (value?.trim().length ?? 0) < 2 ? 'Enter your full name' : null;

  static String? registrationNumber(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Enter your registration number' : null;

  static String? confirmation(String? value, String password) =>
      value == password ? null : 'Passwords do not match';
}
