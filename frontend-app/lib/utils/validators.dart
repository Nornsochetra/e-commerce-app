// Form validators. Each returns an error message, or null when the value is valid.

String? validateRequired(String? value, String message) => (value == null || value.trim().isEmpty) ? message : null;

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter your email address.';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(v)) return 'Enter a valid email, like you@example.com.';
  return null;
}

/// Passwords are 8–72 characters (same rule as the backend).
String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Enter your password.';
  if (v.length < 8) return 'Use at least 8 characters.';
  if (v.length > 72) return 'Use 72 characters or fewer.';
  return null;
}

/// Phone is optional; when given it must look like a phone number.
String? validatePhone(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return null;
  if (!RegExp(r'^[+\d][\d\s()-]{5,}$').hasMatch(v)) return 'Enter a valid phone number, or leave it blank.';
  return null;
}

/// 0–4 score used by the password strength bar on Register.
int passwordStrength(String password) {
  var score = 0;
  if (password.length >= 8) score++;
  if (RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'\d').hasMatch(password)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password) || password.length >= 12) score++;
  return score > 4 ? 4 : score;
}

/// Checkout delivery address: at least a street and a city.
String? validateAddress(String? value) => (value?.trim().length ?? 0) < 8 ? 'Enter a full delivery address (street, city).' : null;
