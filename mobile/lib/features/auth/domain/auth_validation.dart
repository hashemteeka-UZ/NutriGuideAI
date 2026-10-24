final RegExp authEmailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

const int authPasswordMinLength = 8;
const int authPasswordMaxLength = 128;

String? validateEmail(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return 'required';
  }
  if (!authEmailPattern.hasMatch(value)) {
    return 'invalid';
  }
  return null;
}

String? validateRegisterPassword(String password) {
  if (password.length < authPasswordMinLength) {
    return 'short';
  }
  if (password.length > authPasswordMaxLength) {
    return 'long';
  }
  return null;
}

String? validateLoginPassword(String password) {
  if (password.isEmpty) {
    return 'required';
  }
  if (password.length > authPasswordMaxLength) {
    return 'long';
  }
  return null;
}
