import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/motion/interactive_card.dart';
import '../../core/motion/motion_reveal.dart';
import '../../services/campus_location_service.dart';
import '../../services/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final devLocationMode = ref.watch(devLocationModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Information Header
                  MotionReveal.staggered(
                    index: 0,
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                'assets/images/campusfix_logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.apartment_rounded,
                                  size: 34,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppConstants.appName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Version ${AppConstants.appVersion}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'LBRCE Campus Operations',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // DEVELOPER TOOLS SECTION (STRICTLY DEBUG MODE ONLY)
                  if (kDebugMode) ...[
                    MotionReveal.staggered(
                      index: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.developer_mode_rounded, size: 18, color: Colors.amber.shade800),
                              const SizedBox(width: 8),
                              Text(
                                'DEVELOPER TOOLS (DEBUG)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amber.shade900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          InteractiveCard(
                            onTap: () {
                              Navigator.pushNamed(context, AppRoutes.developerTools);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.location_searching_rounded, color: Colors.amber.shade800, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Campus Location Testing',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          devLocationMode == DevLocationTestingMode.realGps
                                              ? 'Real GPS (Enforcing LBRCE geofence)'
                                              : (devLocationMode == DevLocationTestingMode.simulateInsideCampus
                                                  ? 'Simulate Inside LBRCE Campus'
                                                  : 'Simulate Outside Campus'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: devLocationMode == DevLocationTestingMode.realGps
                                                ? AppColors.primary
                                                : (devLocationMode == DevLocationTestingMode.simulateInsideCampus
                                                    ? AppColors.successDark
                                                    : AppColors.errorDark),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.lightTextMuted),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],

                  // Campus Information Section
                  MotionReveal.staggered(
                    index: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CAMPUS LOCATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  icon: Icons.school_rounded,
                                  title: 'Institution',
                                  value: CampusLocationService.campusName,
                                  isDark: isDark,
                                ),
                                const Divider(height: 20),
                                _buildInfoRow(
                                  icon: Icons.pin_drop_rounded,
                                  title: 'Center Coordinates',
                                  value: '${CampusLocationService.campusLatitude}° N, ${CampusLocationService.campusLongitude}° E',
                                  isDark: isDark,
                                ),
                                const Divider(height: 20),
                                _buildInfoRow(
                                  icon: Icons.radar_rounded,
                                  title: 'Allowed Radius',
                                  value: '${CampusLocationService.allowedRadiusMeters.toInt()} meters (1.5 km)',
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account Actions Section
                  MotionReveal.staggered(
                    index: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SESSION & ACCOUNT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                                title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                                trailing: const Icon(Icons.chevron_right_rounded),
                                onTap: () {
                                  Navigator.pushNamed(context, AppRoutes.forgotPassword);
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                                title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
                                onTap: () async {
                                  final auth = ref.read(authServiceProvider);
                                  await auth.signOut();
                                  if (context.mounted) {
                                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
