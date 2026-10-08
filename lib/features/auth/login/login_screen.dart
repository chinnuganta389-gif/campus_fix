import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/motion/motion_reveal.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/campusfix_brand_logo.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../services/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(AppConstants.keyRememberUser);
    if (savedEmail != null && savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final userModel = await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString(AppConstants.keyRememberUser, _emailController.text.trim());
      } else {
        await prefs.remove(AppConstants.keyRememberUser);
      }

      if (!mounted) return;

      _routeByRole(userModel.role);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('AppException: ', '');
        _isLoading = false;
      });
    }
  }

  void _routeByRole(String role) {
    switch (role.toLowerCase()) {
      case AppConstants.roleStaff:
        Navigator.pushReplacementNamed(context, AppRoutes.staffDashboard);
        break;
      case AppConstants.roleWorker:
        Navigator.pushReplacementNamed(context, AppRoutes.workerDashboard);
        break;
      case AppConstants.roleAdmin:
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        break;
      case AppConstants.roleStudent:
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard);
        break;
    }
  }

  void _quickFillRole(String role) {
    setState(() {
      _passwordController.text = 'password123';
      switch (role) {
        case AppConstants.roleStaff:
          _emailController.text = 'staff@lbrce.ac.in';
          break;
        case AppConstants.roleWorker:
          _emailController.text = 'worker@lbrce.ac.in';
          break;
        case AppConstants.roleAdmin:
          _emailController.text = 'admin@lbrce.ac.in';
          break;
        case AppConstants.roleStudent:
        default:
          _emailController.text = 'student@lbrce.ac.in';
          break;
      }
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: isDesktop ? _buildDesktopLayout(size) : _buildMobileLayout(size),
    );
  }

  // -------------------------------------------------------------------------
  // DESKTOP FULL-SCREEN SPLIT HERO + LOGIN CARD LAYOUT
  // -------------------------------------------------------------------------
  Widget _buildDesktopLayout(Size size) {
    return Row(
      children: [
        // Left Hero Area with Campus Image + Dark Navy Gradient Overlay
        Expanded(
          flex: 11,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // High-Definition LBRCE Campus Photo
              Image.asset(
                'assets/images/lbrce_campus.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.primaryDark,
                ),
              ),

              // Deep Navy Gradient Overlay + Vignette
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC062B55), // 80% opacity Deep Navy
                      Color(0xEE041E3D), // 93% opacity Deep Navy
                      Color(0xFA021224), // 98% opacity
                    ],
                  ),
                ),
              ),

              // Subtle blue radial ambient glow
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brightBlue.withValues(alpha: 0.15),
                  ),
                ),
              ),

              // Hero Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top University Pill
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.school_rounded, color: AppColors.accentCyan, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'LBRCE AUTONOMOUS CAMPUS OPERATIONS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Center Hero Title & Tagline
                      MotionReveal(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome to',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF90CDF4),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text(
                                  'Campus',
                                  style: TextStyle(
                                    fontSize: 54,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1.5,
                                    height: 1.1,
                                  ),
                                ),
                                const Text(
                                  'Fix',
                                  style: TextStyle(
                                    fontSize: 54,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.accentCyan,
                                    letterSpacing: -1.5,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Lakireddy Bali Reddy College of Engineering',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF1F5F9),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Mylavaram, NTR District, Andhra Pradesh',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.brightBlue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.brightBlue.withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                'Fixing Campus. Improving Life.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentCyan,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),

                            // 3 Feature Indicators
                            Row(
                              children: [
                                _buildHeroFeature(Icons.report_problem_outlined, 'Report Problems'),
                                const SizedBox(width: 20),
                                _buildHeroFeature(Icons.timeline_rounded, 'Track Progress'),
                                const SizedBox(width: 20),
                                _buildHeroFeature(Icons.verified_rounded, 'Better Campus'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Bottom Feature Bar
                      _buildBottomFeatureBar(isDark: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right Side: Modern Floating Login Card Container
        Expanded(
          flex: 9,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: _buildLoginCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // MOBILE / TABLET STACKED LAYOUT
  // -------------------------------------------------------------------------
  Widget _buildMobileLayout(Size size) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Top Mobile Hero Header with Campus Banner
          Stack(
            children: [
              SizedBox(
                height: 220,
                width: double.infinity,
                child: Image.asset(
                  'assets/images/lbrce_campus.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(color: AppColors.primary),
                ),
              ),
              Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xB3062B55),
                      Color(0xF5061E38),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CampusFixBrandLogo(
                      logoSize: 36,
                      isDark: true,
                      showCollegeDetails: true,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Login Form Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: _buildLoginCard(),
            ),
          ),

          // Mobile Bottom Feature Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: _buildBottomFeatureBar(isDark: false),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroFeature(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: AppColors.accentCyan, size: 18),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // FLOATING LOGIN CARD
  // -------------------------------------------------------------------------
  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF062B55).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Center Logo & Welcome Header
            const Center(
              child: CampusFixBrandLogo(
                logoSize: 48,
                isDark: false,
                showCollegeDetails: false,
                isCentered: true,
              ),
            ),
            const SizedBox(height: 18),

            const Center(
              child: Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Access your dashboard and manage campus services.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 26),

            // Error Message Banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.errorDark,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // College Email Field
            CustomTextField(
              controller: _emailController,
              label: 'College Email',
              hintText: 'user@lbrce.ac.in',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),

            // Password Field
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: Validators.validatePassword,
              onFieldSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 14),

            // Remember Me & Forgot Password Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) => setState(() => _rememberMe = val ?? true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Remember Me',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Primary Gradient LOGIN Button
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: _isLoading ? null : AppColors.buttonGradient,
                color: _isLoading ? AppColors.secondary.withValues(alpha: 0.6) : null,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brightBlue.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _isLoading ? null : _handleLogin,
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Role Quick Access Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.lightBorder)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'QUICK ROLE LOGIN',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.lightTextSecondary),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.lightBorder)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildRoleChip('Student', Icons.school_outlined, AppConstants.roleStudent)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildRoleChip('Staff', Icons.badge_outlined, AppConstants.roleStaff)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildRoleChip('Worker', Icons.engineering_outlined, AppConstants.roleWorker)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildRoleChip('Admin', Icons.admin_panel_settings_outlined, AppConstants.roleAdmin)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Don't have an account link
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                  child: const Text(
                    'Register Now',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String label, IconData icon, String roleKey) {
    return InkWell(
      onTap: () => _quickFillRole(roleKey),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.secondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // BOTTOM FEATURE BAR
  // -------------------------------------------------------------------------
  Widget _buildBottomFeatureBar({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.lightBorder),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 14,
        runSpacing: 8,
        children: [
          _buildBottomFeature('⚡ Fast Response', isDark),
          _buildBottomFeature('📊 Smart Monitoring', isDark),
          _buildBottomFeature('🛡 Safe & Secure', isDark),
          _buildBottomFeature('🏫 Campus Focused', isDark),
        ],
      ),
    );
  }

  Widget _buildBottomFeature(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFFCBD5E1) : AppColors.lightTextSecondary,
      ),
    );
  }
}
