import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/providers.dart';
import '../auth/login/login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _blueprintFadeAnimation;
  late final Animation<double> _blueprintScaleAnimation;
  late final Animation<double> _blueprintGlowAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _textFadeAnimation;
  late final Animation<Offset> _textSlideAnimation;
  late final Animation<double> _collegeFadeAnimation;
  late final Animation<Offset> _collegeSlideAnimation;
  late final Animation<double> _taglineFadeAnimation;
  late final Animation<Offset> _taglineSlideAnimation;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // 0.0s - 0.40s: Thin campus line-art gradually reveals across screen
    _blueprintFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOut),
      ),
    );

    // Subtle architectural camera drift / scale
    _blueprintScaleAnimation = Tween<double>(begin: 1.05, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    // Subtle glowing architectural strokes / pencil pulse
    _blueprintGlowAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.15, 0.65, curve: Curves.easeInOut),
      ),
    );

    // 0.25s - 0.55s: Logo softly fades in
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.22, 0.55, curve: Curves.easeOut),
      ),
    );

    // 0.25s - 0.60s: Logo scales from approximately 85% -> 100%
    _logoScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.22, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    // Subtle glow appears around logo
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeInOut),
      ),
    );

    // 0.45s - 0.75s: CampusFix text fades/slides upward
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // 0.55s - 0.85s: College name and location appear
    _collegeFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );
    _collegeSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // 0.68s - 0.95s: Tagline fades in
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.68, 0.95, curve: Curves.easeOut),
      ),
    );
    _taglineSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.68, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();
    _handleRouting();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRouting() async {
    // Wait for the full cinematic sketch + logo sequence to finish (approx. 2300ms)
    await Future.delayed(const Duration(milliseconds: 2300));
    if (!mounted || _isNavigating) return;
    _isNavigating = true;

    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;

    if (user != null) {
      try {
        final profile = await authService.getUserProfile(user.uid);
        if (!mounted) return;

        if (profile != null && profile.isActive) {
          _routeWithFadeToRole(profile.role);
          return;
        }
      } catch (_) {
        // Fallback to login
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool(AppConstants.keyHasSeenOnboarding) ?? false;

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      _routeWithFade(AppRoutes.onboarding);
    } else {
      _routeWithFadeToLogin();
    }
  }

  void _routeWithFadeToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _routeWithFade(String routeName) {
    Navigator.pushReplacementNamed(context, routeName);
  }

  void _routeWithFadeToRole(String role) {
    String route;
    switch (role.toLowerCase()) {
      case AppConstants.roleStaff:
        route = AppRoutes.staffDashboard;
        break;
      case AppConstants.roleWorker:
        route = AppRoutes.workerDashboard;
        break;
      case AppConstants.roleAdmin:
        route = AppRoutes.adminDashboard;
        break;
      case AppConstants.roleStudent:
      default:
        route = AppRoutes.studentDashboard;
        break;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Responsive Logo Sizing:
    // Mobile: 110–130px | Tablet: 140–160px | Desktop: 160–180px
    final double logoSize = width < 600
        ? 120.0
        : (width < 1024 ? 150.0 : 170.0);

    return Scaffold(
      backgroundColor: AppColors.primary, // Deep CampusFix Navy #062B55
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Base Deep Navy Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF041A35),
                  Color(0xFF062B55),
                  Color(0xFF021224),
                ],
              ),
            ),
          ),

          // Architectural LBRCE Blueprint / Line-art Background Layer
          FadeTransition(
            opacity: _blueprintFadeAnimation,
            child: ScaleTransition(
              scale: _blueprintScaleAnimation,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/lbrce_blueprint.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),

                  // Architectural subtle glow/sketch pulse
                  AnimatedBuilder(
                    animation: _blueprintGlowAnimation,
                    builder: (context, child) {
                      return Container(
                        color: AppColors.accentCyan.withValues(
                          alpha: 0.05 * _blueprintGlowAnimation.value,
                        ),
                      );
                    },
                  ),

                  // Dark Navy Vignette / Scrim to guarantee foreground readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.15,
                        colors: [
                          const Color(0xFF062B55).withValues(alpha: 0.65),
                          const Color(0xFF021224).withValues(alpha: 0.88),
                        ],
                      ),
                    ),
                  ),

                  // Directional gradient to ground the building
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF041A35).withValues(alpha: 0.60),
                          Colors.transparent,
                          const Color(0xFF021224).withValues(alpha: 0.85),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Centered Foreground Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Logo with subtle glow and clean scale
                      FadeTransition(
                        opacity: _logoFadeAnimation,
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: Container(
                            width: logoSize,
                            height: logoSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(logoSize * 0.28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brightBlue.withValues(
                                    alpha: 0.35 * _glowAnimation.value,
                                  ),
                                  blurRadius: 28 * _glowAnimation.value + 4,
                                  spreadRadius: 1 * _glowAnimation.value,
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
                                errorBuilder: (context, error, stackTrace) => Container(
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
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // CampusFix Title (Fade + Slide Upward)
                      FadeTransition(
                        opacity: _textFadeAnimation,
                        child: SlideTransition(
                          position: _textSlideAnimation,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Campus',
                                style: TextStyle(
                                  fontSize: width < 600 ? 34 : 40,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              Text(
                                'Fix',
                                style: TextStyle(
                                  fontSize: width < 600 ? 34 : 40,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accentCyan,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // College Affiliation (Sequential Reveal)
                      FadeTransition(
                        opacity: _collegeFadeAnimation,
                        child: SlideTransition(
                          position: _collegeSlideAnimation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lakireddy Bali Reddy College of Engineering',
                                style: TextStyle(
                                  fontSize: width < 600 ? 13 : 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE2E8F0),
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Mylavaram, NTR District, Andhra Pradesh',
                                style: TextStyle(
                                  fontSize: width < 600 ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Tagline: "Fixing Campus. Improving Life."
                      FadeTransition(
                        opacity: _taglineFadeAnimation,
                        child: SlideTransition(
                          position: _taglineSlideAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.accentCyan.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'Fixing Campus. Improving Life.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentCyan,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
