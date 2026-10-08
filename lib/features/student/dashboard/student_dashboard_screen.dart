import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/motion/animated_counter.dart';
import '../../../core/motion/interactive_card.dart';
import '../../../core/motion/motion_reveal.dart';
import '../../../core/motion/parallax_container.dart';
import '../../../core/motion/shimmer_loading.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/responsive_scaffold.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/complaint_model.dart';
import '../../../services/campus_location_service.dart';
import '../../../services/providers.dart';
import '../complaints/student_complaints_screen.dart';
import '../profile/student_profile_screen.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  int _currentIndex = 0;
  late final ScrollController _scrollController;
  CampusLocationResult? _liveLocationStatus;
  bool _isCheckingGps = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _refreshCampusStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshCampusStatus() async {
    if (_isCheckingGps) return;
    setState(() => _isCheckingGps = true);
    final devMode = ref.read(devLocationModeProvider);
    final service = ref.read(campusLocationServiceProvider);
    final result = await service.verifyCampusLocation(testMode: devMode);
    if (mounted) {
      setState(() {
        _liveLocationStatus = result;
        _isCheckingGps = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showTrackComplaintModal(BuildContext context, List<ComplaintModel> allComplaints) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final query = searchCtrl.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? allComplaints
              : allComplaints.where((c) =>
                  c.complaintId.toLowerCase().contains(query) ||
                  c.title.toLowerCase().contains(query) ||
                  c.category.toLowerCase().contains(query)).toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Track Complaint',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by Ticket ID (e.g. CF-2026-...) or keyword',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                searchCtrl.clear();
                                setModalState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text('No complaints matching your search query.'),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 20),
                            ),
                            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            subtitle: Text('${item.complaintId} • ${item.location}', style: const TextStyle(fontSize: 12)),
                            trailing: StatusBadge(status: item.status, isCompact: true),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(context, AppRoutes.complaintDetail, arguments: item);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final navigationItems = [
      const NavigationItem(
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
      ),
      const NavigationItem(
        label: 'My Complaints',
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment_rounded,
      ),
      const NavigationItem(
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
    ];

    final pages = [
      _buildHomeView(),
      const StudentComplaintsScreen(),
      const StudentProfileScreen(),
    ];

    return ResponsiveScaffold(
      title: 'CampusFix',
      showAppBar: _currentIndex == 0,
      currentIndex: _currentIndex,
      onNavigationChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      items: navigationItems,
      actions: _currentIndex == 0
          ? [
              // Notification Bell
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.notifications);
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Settings Button
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.settingsRoute);
                },
              ),
              const SizedBox(width: 8),
            ]
          : null,
      body: pages[_currentIndex],
    );
  }

  Widget _buildHomeView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(currentUserProfileProvider);
    final complaintsAsync = ref.watch(studentComplaintsProvider);
    final devMode = ref.watch(devLocationModeProvider);

    return userAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20.0),
        child: SkeletonComplaintList(count: 3),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (user) {
        final userName = user?.name.split(' ').first ?? 'Student';

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studentComplaintsProvider);
            await _refreshCampusStatus();
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP HEADER: Greeting, Campus Status Pill & Avatar
                    MotionReveal.staggered(
                      index: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${_getGreeting()},',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Campus Status Badge Pill
                                    _buildCampusPill(isDark, devMode),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.name ?? userName,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          AvatarImage(
                            name: user?.name ?? 'U',
                            imageUrl: user?.profileImage,
                            radius: 24,
                            onTap: () {
                              setState(() {
                                _currentIndex = 2; // Jump to profile tab
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // WELCOME HERO CARD
                    MotionReveal.staggered(
                      index: 1,
                      child: ParallaxContainer(
                        scrollController: _scrollController,
                        parallaxFactor: 0.12,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'CAMPUS MAINTENANCE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Good Morning, $userName',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Keep your campus better by reporting problems. Technicians will be assigned right away.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              CustomButton(
                                text: 'REPORT A PROBLEM',
                                icon: Icons.add_circle_outline_rounded,
                                height: 46,
                                variant: ButtonVariant.secondary,
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.reportProblem);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // QUICK ACTIONS (4 interactive buttons)
                    MotionReveal.staggered(
                      index: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionItem(
                                  title: 'Report Problem',
                                  icon: Icons.add_alert_rounded,
                                  color: AppColors.primary,
                                  isDark: isDark,
                                  onTap: () => Navigator.pushNamed(context, AppRoutes.reportProblem),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildQuickActionItem(
                                  title: 'My Complaints',
                                  icon: Icons.folder_shared_rounded,
                                  color: const Color(0xFF0D9488),
                                  isDark: isDark,
                                  onTap: () => setState(() => _currentIndex = 1),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildQuickActionItem(
                                  title: 'Track Ticket',
                                  icon: Icons.track_changes_rounded,
                                  color: const Color(0xFF8B5CF6),
                                  isDark: isDark,
                                  onTap: () => _showTrackComplaintModal(context, complaintsAsync.value ?? []),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildQuickActionItem(
                                  title: 'Notifications',
                                  icon: Icons.notifications_active_rounded,
                                  color: const Color(0xFFF59E0B),
                                  isDark: isDark,
                                  onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // STATISTICS OVERVIEW
                    MotionReveal.staggered(
                      index: 3,
                      child: Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    complaintsAsync.when(
                      loading: () => const SkeletonStatGrid(),
                      error: (err, _) => Text('Error loading statistics: $err'),
                      data: (complaints) {
                        final total = complaints.length;
                        final pending = complaints.where((c) => c.status == AppConstants.statusPending).length;
                        final inProgress = complaints.where((c) => c.status == AppConstants.statusInProgress || c.status == AppConstants.statusAssigned).length;
                        final resolved = complaints.where((c) => c.status == AppConstants.statusResolved).length;

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard('Total Complaints', total, Icons.assignment_outlined, AppColors.primary, isDark),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard('Pending', pending, Icons.schedule_rounded, AppColors.warning, isDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard('In Progress', inProgress, Icons.engineering_rounded, AppColors.info, isDark),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatCard('Resolved', resolved, Icons.check_circle_outline_rounded, AppColors.success, isDark),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),

                    // CAMPUS STATUS CARD
                    MotionReveal.staggered(
                      index: 4,
                      child: _buildCampusStatusCard(isDark, devMode),
                    ),
                    const SizedBox(height: 22),

                    // CAMPUS IMPACT SECTION
                    complaintsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (complaints) {
                        final reported = complaints.length;
                        final resolved = complaints.where((c) => c.status == AppConstants.statusResolved).length;
                        final contributionPercent = reported > 0 ? ((resolved / reported) * 100).toInt() : 0;

                        return MotionReveal.staggered(
                          index: 5,
                          child: _buildCampusImpactCard(
                            reported: reported,
                            resolved: resolved,
                            contributionPercent: contributionPercent,
                            isDark: isDark,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // RECENT COMPLAINTS
                    MotionReveal.staggered(
                      index: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Complaints',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _currentIndex = 1; // My Complaints
                              });
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    complaintsAsync.when(
                      loading: () => const SkeletonComplaintList(count: 2),
                      error: (err, _) => Text('Error: $err'),
                      data: (complaints) {
                        if (complaints.isEmpty) {
                          return const EmptyView(
                            title: 'No Complaints Yet',
                            message: 'All campus systems in your radar look great!',
                            icon: Icons.check_circle_outline_rounded,
                          );
                        }

                        final recent = complaints.take(4).toList();
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recent.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = recent[index];
                            return MotionReveal.staggered(
                              index: 7 + index,
                              child: _buildEnhancedComplaintCard(item, isDark),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCampusPill(bool isDark, DevLocationTestingMode devMode) {
    if (_liveLocationStatus == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Checking GPS...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      );
    }

    final isInside = _liveLocationStatus!.isInsideCampus;
    final isDevSim = _liveLocationStatus!.mode == 'DEBUG_TEST' && isInside;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDevSim
            ? Colors.amber.withValues(alpha: 0.2)
            : (isInside ? AppColors.successContainer : AppColors.errorContainer),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDevSim
              ? Colors.amber.shade700
              : (isInside ? AppColors.success : AppColors.error),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isInside ? Icons.verified_rounded : Icons.location_off_rounded,
            size: 12,
            color: isDevSim ? Colors.amber.shade900 : (isInside ? AppColors.successDark : AppColors.errorDark),
          ),
          const SizedBox(width: 4),
          Text(
            isDevSim ? 'LBRCE (Dev Mode)' : (isInside ? 'LBRCE Campus' : 'Outside Campus'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDevSim ? Colors.amber.shade900 : (isInside ? AppColors.successDark : AppColors.errorDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InteractiveCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color, bool isDark) {
    return InteractiveCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCounter(
                  value: count,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusStatusCard(bool isDark, DevLocationTestingMode devMode) {
    final isInside = _liveLocationStatus != null && _liveLocationStatus!.isInsideCampus;
    final isDevTest = _liveLocationStatus != null && _liveLocationStatus!.mode == 'DEBUG_TEST' && isInside;

    return InteractiveCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isInside ? Icons.verified_user_rounded : Icons.location_off_rounded,
                    color: isDevTest ? Colors.amber.shade800 : (isInside ? AppColors.success : AppColors.error),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Campus Status',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: _isCheckingGps
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 20),
                tooltip: 'Check GPS Location',
                onPressed: _isCheckingGps ? null : _refreshCampusStatus,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDevTest
                      ? Colors.amber.withValues(alpha: 0.2)
                      : (isInside ? AppColors.successContainer : AppColors.errorContainer),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isDevTest ? 'DEVELOPER TEST MODE' : (isInside ? 'INSIDE CAMPUS' : 'OUTSIDE CAMPUS'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDevTest ? Colors.amber.shade900 : (isInside ? AppColors.successDark : AppColors.errorDark),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _liveLocationStatus != null
                      ? 'GPS Accuracy: ${_liveLocationStatus!.accuracy?.toInt() ?? 5}m'
                      : 'GPS checking in progress...',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isInside
                ? 'You are authorized to report issues across LBRCE Mylavaram campus facilities.'
                : 'Complaint submission is restricted to students physically present inside LBRCE campus.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.3,
            ),
          ),
          if (kDebugMode && devMode != DevLocationTestingMode.realGps) ...[
            const SizedBox(height: 10),
            Text(
              '⚠️ Active Bypass: ${devMode == DevLocationTestingMode.simulateInsideCampus ? "Simulated Inside LBRCE" : "Simulated Outside"}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.amber.shade800),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCampusImpactCard({
    required int reported,
    required int resolved,
    required int contributionPercent,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Campus Impact',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Problems Reported', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    const SizedBox(height: 2),
                    Text('$reported', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Problems Resolved', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    const SizedBox(height: 2),
                    Text('$resolved', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.successDark)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Contribution', style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    const SizedBox(height: 2),
                    Text('$contributionPercent%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedComplaintCard(ComplaintModel item, bool isDark) {
    double progress = 0.25;
    if (item.status == AppConstants.statusAssigned) progress = 0.50;
    if (item.status == AppConstants.statusInProgress) progress = 0.75;
    if (item.status == AppConstants.statusResolved) progress = 1.0;

    return InteractiveCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(14),
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.complaintDetail, arguments: item);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Small Evidence Thumbnail or Category Icon
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
                    child: item.imageUrl!.startsWith('data:image')
                        ? Image.memory(
                            base64Decode(item.imageUrl!.split(',')[1]),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.image_outlined, size: 22),
                          )
                        : Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.image_outlined, size: 22),
                          ),
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.report_problem_outlined, color: AppColors.primary, size: 22),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.complaintId,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        StatusBadge(status: item.status, isCompact: true),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${item.location} • ${DateFormatter.formatRelative(item.createdAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Lifecycle Progress Indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                item.status == AppConstants.statusResolved ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
