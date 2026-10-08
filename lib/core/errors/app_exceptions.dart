/// Production-quality error handling & human-readable error messages
class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;

  /// Transform Firebase Authentication error codes to user-friendly messages
  factory AppException.fromFirebaseAuth(String code, [String? fallbackMessage]) {
    switch (code) {
      case 'user-not-found':
        return AppException('No account found with this email address.', code);
      case 'wrong-password':
      case 'invalid-credential':
        return AppException('Incorrect email or password. Please try again.', code);
      case 'email-already-in-use':
        return AppException('An account already exists with this email address.', code);
      case 'invalid-email':
        return AppException('Please enter a valid email address.', code);
      case 'weak-password':
        return AppException('Password must be at least 6 characters long.', code);
      case 'user-disabled':
        return AppException('This account has been deactivated. Please contact campus admin.', code);
      case 'too-many-requests':
        return AppException('Too many unsuccessful attempts. Please try again in a few minutes.', code);
      case 'network-request-failed':
        return AppException('Network error. Please check your internet connection.', code);
      case 'operation-not-allowed':
        return AppException('Email/password login is currently not enabled.', code);
      default:
        return AppException(
          fallbackMessage ?? 'Authentication failed. Please verify your details and try again.',
          code,
        );
    }
  }

  /// Transform Firestore / Storage errors
  factory AppException.fromFirebase(dynamic error) {
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('permission-denied') || errorString.contains('permission denied')) {
      return AppException('Access denied. You do not have permission to perform this action.');
    } else if (errorString.contains('unavailable') || errorString.contains('network')) {
      return AppException('Service is temporarily unavailable or you are offline.');
    } else if (errorString.contains('not-found') || errorString.contains('not found')) {
      return AppException('Requested item could not be found.');
    }
    return AppException('An unexpected error occurred. Please try again.');
  }
}
