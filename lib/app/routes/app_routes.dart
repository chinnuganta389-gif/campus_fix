import 'package:flutter/material.dart';
import '../../core/motion/page_transitions.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/register/register_screen.dart';
import '../../features/auth/forgot_password/forgot_password_screen.dart';
import '../../features/student/dashboard/student_dashboard_screen.dart';
import '../../features/student/report_problem/report_problem_screen.dart';
import '../../features/student/complaints/complaint_detail_screen.dart';
import '../../features/staff/dashboard/staff_dashboard_screen.dart';
import '../../features/worker/dashboard/worker_dashboard_screen.dart';
import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/developer_tools_screen.dart';
import '../../models/complaint_model.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  static const String studentDashboard = '/student';
  static const String reportProblem = '/student/report';
  static const String complaintDetail = '/complaint/detail';

  static const String staffDashboard = '/staff';
  static const String workerDashboard = '/worker';
  static const String adminDashboard = '/admin';
  static const String notifications = '/notifications';
  static const String settingsRoute = '/settings';
  static const String developerTools = '/developer-tools';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      case onboarding:
        return CinematicPageRoute(
          settings: settings,
          child: const OnboardingScreen(),
        );
      case login:
        return CinematicPageRoute(
          settings: settings,
          child: const LoginScreen(),
        );
      case register:
        return CinematicPageRoute(
          settings: settings,
          child: const RegisterScreen(),
        );
      case forgotPassword:
        return CinematicPageRoute(
          settings: settings,
          child: const ForgotPasswordScreen(),
        );
      case studentDashboard:
        return CinematicPageRoute(
          settings: settings,
          child: const StudentDashboardScreen(),
        );
      case reportProblem:
        return CinematicPageRoute(
          settings: settings,
          child: const ReportProblemScreen(),
        );
      case complaintDetail:
        final complaint = settings.arguments as ComplaintModel;
        return CinematicPageRoute(
          settings: settings,
          child: ComplaintDetailScreen(complaint: complaint),
        );
      case staffDashboard:
        return CinematicPageRoute(
          settings: settings,
          child: const StaffDashboardScreen(),
        );
      case workerDashboard:
        return CinematicPageRoute(
          settings: settings,
          child: const WorkerDashboardScreen(),
        );
      case adminDashboard:
        return CinematicPageRoute(
          settings: settings,
          child: const AdminDashboardScreen(),
        );
      case notifications:
        return CinematicPageRoute(
          settings: settings,
          child: const NotificationsScreen(),
        );
      case settingsRoute:
        return CinematicPageRoute(
          settings: settings,
          child: const SettingsScreen(),
        );
      case developerTools:
        return CinematicPageRoute(
          settings: settings,
          child: const DeveloperToolsScreen(),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
