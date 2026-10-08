import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum LocationValidationStatus {
  idle,
  checking,
  verified,
  outsideCampus,
  permissionDenied,
  serviceDisabled,
  timeout,
  error,
}

/// Developer Testing Modes for Campus Geofencing (DEBUG MODE ONLY)
enum DevLocationTestingMode {
  realGps,              // Real GPS — enforce LBRCE geofence (Default)
  simulateInsideCampus, // Simulate Inside LBRCE Campus
  simulateOutsideCampus // Simulate Outside LBRCE Campus (e.g., Ongole / Home)
}

class CampusLocationResult {
  final bool isVerified;
  final bool isInsideCampus;
  final LocationValidationStatus status;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? distanceMeters;
  final String message;
  final DateTime verifiedAt;
  final String mode; // "REAL_GPS" or "DEBUG_TEST"
  final String? reason; // e.g. "Developer testing"

  CampusLocationResult({
    required this.isVerified,
    required this.isInsideCampus,
    required this.status,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.distanceMeters,
    required this.message,
    DateTime? verifiedAt,
    this.mode = 'REAL_GPS',
    this.reason,
  }) : verifiedAt = verifiedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'distanceMeters': distanceMeters != null ? double.parse(distanceMeters!.toStringAsFixed(1)) : null,
      'verified': isVerified,
      'verifiedAt': verifiedAt.toIso8601String(),
      'mode': mode,
      if (reason != null) 'reason': reason,
    };
  }
}

/// Centralized Campus Location & Geofencing Configuration & Service for LBRCE Mylavaram
class CampusLocationService {
  // ====================================================
  // CENTRALIZED LBRCE CAMPUS CONFIGURATION
  // Lakireddy Bali Reddy College of Engineering, Mylavaram
  // ====================================================
  static const String campusName = 'LBRCE (Lakireddy Bali Reddy College of Engineering), Mylavaram';
  static const double campusLatitude = 16.7491;
  static const double campusLongitude = 80.6324;
  static const double allowedRadiusMeters = 1500.0; // 1.5 km campus radius

  /// Calculate distance in meters using Haversine formula (pure Dart fallback)
  static double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    const double earthRadiusMeters = 6371000.0;
    final double dLat = _degToRad(endLatitude - startLatitude);
    final double dLon = _degToRad(endLongitude - startLongitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(startLatitude)) *
            math.cos(_degToRad(endLatitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Verify whether the student is physically within the LBRCE campus geofence
  Future<CampusLocationResult> verifyCampusLocation({
    DevLocationTestingMode testMode = DevLocationTestingMode.realGps,
  }) async {
    debugPrint('[CampusFix] Location verification started');

    // =========================================================================
    // SECURITY RULE: IN RELEASE BUILDS, DEVELOPER TESTING BYPASS IS IMPOSSIBLE
    // =========================================================================
    if (!kDebugMode) {
      // Release builds unconditionally enforce real GPS against LBRCE
      testMode = DevLocationTestingMode.realGps;
    } else {
      // DEBUG MODE CHECKS
      if (testMode == DevLocationTestingMode.simulateInsideCampus) {
        debugPrint('[CampusFix] [DEBUG_TEST] Simulating Inside LBRCE Campus');
        return CampusLocationResult(
          isVerified: true,
          isInsideCampus: true,
          status: LocationValidationStatus.verified,
          latitude: campusLatitude,
          longitude: campusLongitude,
          accuracy: 5.0,
          distanceMeters: 0.0,
          message: "LBRCE Campus simulated (Developer Test Mode)",
          mode: 'DEBUG_TEST',
          reason: 'Developer testing',
        );
      } else if (testMode == DevLocationTestingMode.simulateOutsideCampus) {
        debugPrint('[CampusFix] [DEBUG_TEST] Simulating Outside LBRCE Campus');
        return CampusLocationResult(
          isVerified: false,
          isInsideCampus: false,
          status: LocationValidationStatus.outsideCampus,
          latitude: 15.5057,
          longitude: 80.0499,
          accuracy: 12.0,
          distanceMeters: 148500.0,
          message: 'Reports can only be submitted while you are inside the college campus.',
          mode: 'DEBUG_TEST',
          reason: 'Developer testing (Simulate Outside)',
        );
      }
    }

    try {
      // 1. Check whether location services are enabled
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );

      if (!isServiceEnabled) {
        debugPrint('[CampusFix] Location services disabled');
        return CampusLocationResult(
          isVerified: false,
          isInsideCampus: false,
          status: LocationValidationStatus.serviceDisabled,
          message: 'Please enable device location services to submit a complaint.',
          mode: 'REAL_GPS',
        );
      }

      // 2. Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 5),
        onTimeout: () => LocationPermission.denied,
      );

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission().timeout(
          const Duration(seconds: 10),
          onTimeout: () => LocationPermission.denied,
        );
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[CampusFix] Location permission denied: $permission');
        return CampusLocationResult(
          isVerified: false,
          isInsideCampus: false,
          status: LocationValidationStatus.permissionDenied,
          message: 'Location permission is required to submit a campus complaint.',
          mode: 'REAL_GPS',
        );
      }

      // 3. Obtain current position with strict timeout
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Timed out waiting for GPS fix');
        },
      );

      // 4. Calculate distance to LBRCE campus center
      final double distance = calculateDistance(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        endLatitude: campusLatitude,
        endLongitude: campusLongitude,
      );

      debugPrint(
        '[CampusFix] Location obtained: (${position.latitude}, ${position.longitude}) - '
        'Accuracy: ${position.accuracy}m - Distance from LBRCE: ${distance.toStringAsFixed(1)}m',
      );

      // 5. Anti-spoofing / poor accuracy check
      if (position.accuracy > 200.0) {
        return CampusLocationResult(
          isVerified: false,
          isInsideCampus: false,
          status: LocationValidationStatus.error,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          distanceMeters: distance,
          message: 'Location accuracy is too low (${position.accuracy.toInt()}m). Please move outdoors.',
          mode: 'REAL_GPS',
        );
      }

      // 6. Check geofence
      if (distance <= allowedRadiusMeters) {
        debugPrint('[CampusFix] Location verification completed: INSIDE LBRCE CAMPUS');
        return CampusLocationResult(
          isVerified: true,
          isInsideCampus: true,
          status: LocationValidationStatus.verified,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          distanceMeters: distance,
          message: "You're inside the campus",
          mode: 'REAL_GPS',
        );
      } else {
        debugPrint('[CampusFix] Location verification completed: OUTSIDE LBRCE CAMPUS ($distance m)');
        return CampusLocationResult(
          isVerified: false,
          isInsideCampus: false,
          status: LocationValidationStatus.outsideCampus,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          distanceMeters: distance,
          message: 'Reports can only be submitted while you are inside the college campus.',
          mode: 'REAL_GPS',
        );
      }
    } on TimeoutException {
      debugPrint('[CampusFix] Location verification timed out');
      return CampusLocationResult(
        isVerified: false,
        isInsideCampus: false,
        status: LocationValidationStatus.timeout,
        message: 'Location check timed out. Please retry with clear sky view.',
        mode: 'REAL_GPS',
      );
    } catch (e) {
      debugPrint('[CampusFix] Location verification error: $e');
      return CampusLocationResult(
        isVerified: false,
        isInsideCampus: false,
        status: LocationValidationStatus.error,
        message: 'Could not verify location: ${e.toString()}',
        mode: 'REAL_GPS',
      );
    }
  }
}
