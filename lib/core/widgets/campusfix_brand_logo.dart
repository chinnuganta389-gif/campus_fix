import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Premium CampusFix + LBRCE Branded Identity Component
class CampusFixBrandLogo extends StatelessWidget {
  final double logoSize;
  final bool isDark;
  final bool showCollegeDetails;
  final bool isCentered;

  const CampusFixBrandLogo({
    super.key,
    this.logoSize = 42,
    this.isDark = true,
    this.showCollegeDetails = true,
    this.isCentered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Logo + Brand Title Row
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo Container
            Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(logoSize * 0.28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brightBlue.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(logoSize * 0.28),
                child: Image.asset(
                  'assets/images/campusfix_logo.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to clean branded monogram
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'CF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: logoSize * 0.42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Brand Titles
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Campus',
                        style: TextStyle(
                          fontSize: logoSize * 0.46,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Fix',
                        style: TextStyle(
                          fontSize: logoSize * 0.46,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: AppColors.accentCyan,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.brightBlue.withValues(alpha: isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'OPERATIONS HUB',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDark ? const Color(0xFF90CDF4) : AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // LBRCE College Affiliation
        if (showCollegeDetails) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text(
                  'Lakireddy Bali Reddy College of Engineering',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFE2E8F0) : AppColors.lightTextPrimary,
                  ),
                  textAlign: isCentered ? TextAlign.center : TextAlign.start,
                ),
                const SizedBox(height: 1),
                Text(
                  'Mylavaram, NTR District, Andhra Pradesh',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.lightTextSecondary,
                  ),
                  textAlign: isCentered ? TextAlign.center : TextAlign.start,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
