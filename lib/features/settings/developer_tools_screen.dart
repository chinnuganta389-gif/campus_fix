import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/motion/motion_reveal.dart';
import '../../services/campus_location_service.dart';
import '../../services/providers.dart';

class DeveloperToolsScreen extends ConsumerWidget {
  const DeveloperToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentDevMode = ref.watch(devLocationModeProvider);

    // SECURITY: If opened in release mode, completely reject access
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Developer Tools')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Developer tools are disabled and unavailable in production release builds.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Debug Alert Badge
                  MotionReveal.staggered(
                    index: 0,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.shade700, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.build_circle_rounded, color: Colors.amber.shade800, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DEBUG MODE ENVIRONMENT',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.amber.shade900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tools in this section are only active during development and are automatically stripped in release builds.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section Title
                  MotionReveal.staggered(
                    index: 1,
                    child: Text(
                      'Campus Location Testing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  MotionReveal.staggered(
                    index: 2,
                    child: Text(
                      'Configure how the application verifies LBRCE campus boundaries during local feature testing.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Options Card
                  MotionReveal.staggered(
                    index: 3,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _buildTestingOption(
                            context: context,
                            ref: ref,
                            title: 'Real GPS — enforce LBRCE geofence',
                            subtitle: 'Queries hardware GPS and enforces real physical proximity to LBRCE Mylavaram (Default).',
                            mode: DevLocationTestingMode.realGps,
                            currentMode: currentDevMode,
                            icon: Icons.my_location_rounded,
                            isDark: isDark,
                          ),
                          const Divider(height: 1),
                          _buildTestingOption(
                            context: context,
                            ref: ref,
                            title: 'Simulate Inside Campus',
                            subtitle: 'Allows complaint submission from outside LBRCE (e.g. Ongole / Home / Remote). Tags submission as DEBUG_TEST.',
                            mode: DevLocationTestingMode.simulateInsideCampus,
                            currentMode: currentDevMode,
                            icon: Icons.verified_user_rounded,
                            isDark: isDark,
                          ),
                          const Divider(height: 1),
                          _buildTestingOption(
                            context: context,
                            ref: ref,
                            title: 'Simulate Outside Campus',
                            subtitle: 'Forces outside geofence state. Submission is blocked exactly as in production.',
                            mode: DevLocationTestingMode.simulateOutsideCampus,
                            currentMode: currentDevMode,
                            icon: Icons.location_off_rounded,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Active Mode Feedback Banner
                  if (currentDevMode == DevLocationTestingMode.simulateInsideCampus) ...[
                    MotionReveal.staggered(
                      index: 4,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF064E3B).withValues(alpha: isDark ? 0.35 : 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.success, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: AppColors.successDark, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'DEVELOPER TEST MODE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.successDark,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Simulated location: LBRCE Campus',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Real GPS geofence bypassed. Submissions will be tagged with verification mode "DEBUG_TEST".',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (currentDevMode == DevLocationTestingMode.simulateOutsideCampus) ...[
                    MotionReveal.staggered(
                      index: 4,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.error, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.block_rounded, color: AppColors.errorDark, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'DEVELOPER TEST MODE — SIMULATING OUTSIDE',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.errorDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Simulated location: Outside LBRCE',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Complaint submission will be blocked with "Campus location required", exactly as in production.',
                              style: TextStyle(fontSize: 13, color: AppColors.errorDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestingOption({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required DevLocationTestingMode mode,
    required DevLocationTestingMode currentMode,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = mode == currentMode;

    return InkWell(
      onTap: () {
        ref.read(devLocationModeProvider.notifier).state = mode;
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ignore: deprecated_member_use
            Radio<DevLocationTestingMode>(
              value: mode,
              // ignore: deprecated_member_use
              groupValue: currentMode,
              activeColor: AppColors.primary,
              // ignore: deprecated_member_use
              onChanged: (val) {
                if (val != null) {
                  ref.read(devLocationModeProvider.notifier).state = val;
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.lightTextMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
