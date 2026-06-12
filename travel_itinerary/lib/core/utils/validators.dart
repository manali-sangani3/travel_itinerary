class Validators {
  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? required(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? amount(String? v) {
    if (v == null || v.isEmpty) return 'Amount is required';
    if (double.tryParse(v) == null) return 'Enter a valid amount';
    if (double.parse(v) < 0) return 'Amount must be positive';
    return null;
  }
}
