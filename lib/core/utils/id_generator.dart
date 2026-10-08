import 'dart:math';

class IdGenerator {
  IdGenerator._();

  /// Generates a standardized complaint ID format: CF-YEAR-XXXXXX
  /// e.g. CF-2026-004821
  static String generateComplaintId() {
    final year = DateTime.now().year;
    final random = Random();
    final number = random.nextInt(900000) + 100000;
    return 'CF-$year-$number';
  }
}
