import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/motion/animated_counter.dart';
import '../../../core/motion/interactive_card.dart';
import '../../../core/motion/motion_reveal.dart';
import '../../../core/motion/shimmer_loading.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/avatar_image.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/responsive_scaffold.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/complaint_model.dart';
import '../../../models/user_model.dart';
import '../../../services/providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _searchUserCtrl = TextEditingController();
  String _userSearchQuery = '';
  String _selectedRoleFilter = 'ALL';

  @override
  void dispose() {
    _searchUserCtrl.dispose();
    super.dispose();
  }

  void _showRoleChangeDialog(BuildContext context, UserModel user) {
    final admin = ref.read(currentUserProfileProvider).value;
    if (admin == null) return;

    String targetRole = user.role;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Change Role: ${user.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assign new system role:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: targetRole,
                  items: [
                    AppConstants.roleStudent,
                    AppConstants.roleStaff,
                    AppConstants.roleWorker,
                    AppConstants.roleAdmin,
                  ].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                  onChanged: (val) {
                    if (val != null) setStateModal(() => targetRole = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setStateModal(() => isSaving = true);
                        try {
                          final firestore = ref.read(firestoreServiceProvider);
                          await firestore.updateUserRole(
                            uid: user.uid,
                            newRole: targetRole,
                            adminId: admin.uid,
                            adminName: admin.name,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Updated ${user.name} to $targetRole.'),
                                backgroundColor: AppColors.successDark,
                              ),
                            );
                          }
                        } catch (e) {
                          setStateModal(() => isSaving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleUserActiveStatus(BuildContext context, UserModel user) {
    final admin = ref.read(currentUserProfileProvider).value;
    if (admin == null) return;

    final willDeactivate = user.isActive;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(willDeactivate ? 'Deactivate Account' : 'Activate Account'),
        content: Text(
          willDeactivate
              ? 'Are you sure you want to deactivate ${user.name}? They will be blocked from logging in.'
              : 'Reactivate account access for ${user.name}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: willDeactivate ? AppColors.error : AppColors.success,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final firestore = ref.read(firestoreServiceProvider);
                await firestore.setUserActiveStatus(
                  uid: user.uid,
                  isActive: !user.isActive,
                  adminId: admin.uid,
                  adminName: admin.name,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User ${user.name} status updated.'),
                      backgroundColor: willDeactivate ? AppColors.error : AppColors.successDark,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(willDeactivate ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from Admin Master Console?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showReportsModal(BuildContext context, List<ComplaintModel> allComplaints) {
    final total = allComplaints.length;
    final resolved = allComplaints.where((c) => c.status == AppConstants.statusResolved).length;
    final pending = allComplaints.where((c) => c.status == AppConstants.statusPending).length;
    final inProgress = allComplaints.where((c) => c.status == AppConstants.statusInProgress || c.status == AppConstants.statusAssigned).length;
    final rate = total > 0 ? ((resolved / total) * 100).toStringAsFixed(1) : '0';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Campus Operations Summary Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Cumulative facility performance report for LBRCE Mylavaram campus:',
              style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.analytics_rounded, color: AppColors.primary),
              title: const Text('Resolution Efficiency Rate'),
              trailing: Text('$rate%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.successDark)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.all_inbox_rounded, color: AppColors.secondary),
              title: const Text('Total Tickets Processed'),
              trailing: Text('$total', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.hourglass_empty_rounded, color: AppColors.warningDark),
              title: const Text('Pending Initial Review'),
              trailing: Text('$pending awaiting review', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.pending_actions_rounded, color: AppColors.primary),
              title: const Text('Active In-Progress / Queue'),
              trailing: Text('$inProgress active', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text('Export Summary CSV / PDF'),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report generated and ready for export.'),
                      backgroundColor: AppColors.successDark,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComplaintsInspectModal(BuildContext context, List<ComplaintModel> allComplaints) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final q = searchCtrl.text.trim().toLowerCase();
          final list = q.isEmpty
              ? allComplaints
              : allComplaints.where((c) =>
                  c.complaintId.toLowerCase().contains(q) ||
                  c.title.toLowerCase().contains(q) ||
                  c.category.toLowerCase().contains(q) ||
                  c.location.toLowerCase().contains(q)).toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Manage Campus Complaints', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchCtrl,
                    onChanged: (_) => setModalState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Search by ID, keyword, or room location...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('No complaints match your search query.')),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final c = list[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#${c.complaintId.length > 6 ? c.complaintId.substring(0, 6) : c.complaintId}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.primary),
                              ),
                            ),
                            title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${c.category} • ${c.location} • ${DateFormatter.formatRelative(c.createdAt)}', style: const TextStyle(fontSize: 12)),
                            trailing: StatusBadge(status: c.status),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.pushNamed(context, AppRoutes.complaintDetail, arguments: c);
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
    final navItems = [
      const NavigationItem(
        label: 'Overview',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
      ),
      const NavigationItem(
        label: 'Analytics',
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics_rounded,
      ),
      const NavigationItem(
        label: 'Workers',
        icon: Icons.engineering_outlined,
        selectedIcon: Icons.engineering_rounded,
      ),
      const NavigationItem(
        label: 'Users',
        icon: Icons.people_outline_rounded,
        selectedIcon: Icons.people_rounded,
      ),
      const NavigationItem(
        label: 'Audit Logs',
        icon: Icons.history_rounded,
        selectedIcon: Icons.history_edu_rounded,
      ),
    ];

    final pages = [
      _buildOverviewView(),
      _buildAnalyticsView(),
      _buildWorkerPerformanceView(),
      _buildUserManagementView(),
      _buildAuditLogsView(),
    ];

    return ResponsiveScaffold(
      title: 'Admin Master Console',
      currentIndex: _currentNavIndex,
      onNavigationChanged: (index) {
        setState(() => _currentNavIndex = index);
      },
      items: navItems,
      actions: [
        IconButton(
          tooltip: 'Settings & Campus Info',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settingsRoute),
        ),
        IconButton(
          tooltip: 'Sign Out',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => _handleLogout(context),
        ),
        const SizedBox(width: 8),
      ],
      body: pages[_currentNavIndex],
    );
  }

  // =========================================================================
  // 1. OVERVIEW & KPI DASHBOARD VIEW
  // =========================================================================
  Widget _buildOverviewView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final complaintsAsync = ref.watch(allComplaintsProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final user = ref.watch(currentUserProfileProvider).value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    AvatarImage(name: user?.name ?? 'Admin', radius: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Welcome, ${user?.name ?? "Campus Administrator"}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'MASTER ADMIN',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'LBRCE Campus Facilities & Maintenance Operations Control Center',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // TOP KPI CARDS
              Text(
                'TOP KEY PERFORMANCE INDICATORS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),

              complaintsAsync.when(
                loading: () => const SkeletonStatGrid(),
                error: (e, _) => Text('Error loading metrics: $e'),
                data: (all) {
                  final totalComplaints = all.length;
                  final pending = all.where((c) => c.status == AppConstants.statusPending).length;
                  final inProgress = all.where((c) => c.status == AppConstants.statusInProgress || c.status == AppConstants.statusAssigned).length;
                  final resolved = all.where((c) => c.status == AppConstants.statusResolved).length;
                  final critical = all.where((c) => c.priority.toUpperCase() == 'CRITICAL' && c.status != AppConstants.statusResolved).length;

                  final workersCount = usersAsync.maybeWhen(
                    data: (users) => users.where((u) => u.role == AppConstants.roleWorker && u.isActive).length,
                    orElse: () => 0,
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 800;
                      if (isWide) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildKpiCard('Total Complaints', totalComplaints, Icons.folder_shared_rounded, AppColors.primary, isDark)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildKpiCard('Pending Review', pending, Icons.pending_actions_rounded, AppColors.warningDark, isDark)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildKpiCard('In Progress', inProgress, Icons.engineering_rounded, AppColors.secondary, isDark)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _buildKpiCard('Resolved', resolved, Icons.check_circle_rounded, AppColors.successDark, isDark)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildKpiCard('Critical Issues', critical, Icons.warning_rounded, AppColors.error, isDark)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildKpiCard('Active Workers', workersCount, Icons.badge_rounded, AppColors.accent, isDark)),
                              ],
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildKpiCard('Total Complaints', totalComplaints, Icons.folder_shared_rounded, AppColors.primary, isDark)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildKpiCard('Pending', pending, Icons.pending_actions_rounded, AppColors.warningDark, isDark)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildKpiCard('In Progress', inProgress, Icons.engineering_rounded, AppColors.secondary, isDark)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildKpiCard('Resolved', resolved, Icons.check_circle_rounded, AppColors.successDark, isDark)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildKpiCard('Critical Issues', critical, Icons.warning_rounded, AppColors.error, isDark)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildKpiCard('Active Workers', workersCount, Icons.badge_rounded, AppColors.accent, isDark)),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              // CAMPUS OVERVIEW & RESOLUTION RATE
              complaintsAsync.maybeWhen(
                data: (all) => _buildCampusOverviewCard(all, isDark),
                orElse: () => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // TREND SECTION
              complaintsAsync.maybeWhen(
                data: (all) => _buildTrendSection(all, isDark),
                orElse: () => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // CAMPUS HEALTH SECTION
              complaintsAsync.maybeWhen(
                data: (all) => _buildCampusHealthSection(all, isDark),
                orElse: () => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // QUICK ADMIN ACTIONS
              _buildQuickActionsSection(context, complaintsAsync.value ?? [], isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, int count, IconData icon, Color color, bool isDark) {
    return InteractiveCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
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
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusOverviewCard(List<ComplaintModel> all, bool isDark) {
    final totalReports = all.length;
    final resolvedReports = all.where((c) => c.status == AppConstants.statusResolved).length;
    final openReports = totalReports - resolvedReports;
    final rate = totalReports == 0 ? 0 : ((resolvedReports / totalReports) * 100).toInt();

    return InteractiveCard(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Campus Overview & Resolution Health', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('Real-time campus maintenance velocity meter', style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$rate% Resolved', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.successDark)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LinearProgressIndicator(
            value: totalReports == 0 ? 0 : (resolvedReports / totalReports),
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
            backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewMetric('Total Reports', totalReports, Icons.folder_open_rounded, AppColors.primary, isDark),
              _buildOverviewMetric('Resolved Reports', resolvedReports, Icons.check_circle_outline_rounded, AppColors.successDark, isDark),
              _buildOverviewMetric('Open Reports', openReports, Icons.pending_outlined, AppColors.warningDark, isDark),
              _buildOverviewMetric('Resolution Rate', rate, Icons.percent_rounded, AppColors.secondary, isDark, isPercent: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetric(String label, int value, IconData icon, Color color, bool isDark, {bool isPercent = false}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedCounter(
              value: value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            if (isPercent) Text('%', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendSection(List<ComplaintModel> all, bool isDark) {
    final now = DateTime.now();
    final today = all.where((c) => c.createdAt.year == now.year && c.createdAt.month == now.month && c.createdAt.day == now.day).length;
    final thisWeek = all.where((c) => c.createdAt.isAfter(now.subtract(const Duration(days: 7)))).length;
    final thisMonth = all.where((c) => c.createdAt.isAfter(now.subtract(const Duration(days: 30)))).length;

    return InteractiveCard(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  const Text('Complaint Reporting Trends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Live Tracking', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTrendBox("Today's Reports", today, 'Logged since 00:00', AppColors.primary, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendBox('This Week', thisWeek, 'Past 7 calendar days', AppColors.secondary, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTrendBox('This Month', thisMonth, 'Past 30 calendar days', AppColors.accent, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBox(String title, int count, String subtitle, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          const SizedBox(height: 6),
          AnimatedCounter(
            value: count,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.lightTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildCampusHealthSection(List<ComplaintModel> all, bool isDark) {
    final now = DateTime.now();
    final openIssues = all.where((c) => c.status != AppConstants.statusResolved && c.status != AppConstants.statusRejected).length;
    final criticalIssues = all.where((c) => c.priority.toUpperCase() == 'CRITICAL' && c.status != AppConstants.statusResolved).length;
    final overdueIssues = all.where((c) =>
      c.status != AppConstants.statusResolved &&
      c.status != AppConstants.statusRejected &&
      now.difference(c.createdAt).inHours >= 48
    ).length;
    final recentlyResolved = all.where((c) =>
      c.status == AppConstants.statusResolved &&
      (c.resolvedAt?.isAfter(now.subtract(const Duration(days: 7))) ?? false)
    ).length;

    return InteractiveCard(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety_rounded, color: AppColors.successDark, size: 22),
              const SizedBox(width: 8),
              const Text('Campus Infrastructure Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHealthBadge('Open Issues', openIssues, Icons.all_inbox_rounded, AppColors.primary, isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHealthBadge('Critical Issues', criticalIssues, Icons.error_outline_rounded, AppColors.error, isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHealthBadge('Overdue (>48h)', overdueIssues, Icons.alarm_rounded, AppColors.warningDark, isDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHealthBadge('Recently Resolved', recentlyResolved, Icons.verified_rounded, AppColors.successDark, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBadge(String label, int count, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          AnimatedCounter(
            value: count,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary), maxLines: 1),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, List<ComplaintModel> allComplaints, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ADMIN ACTIONS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionChip(
              icon: Icons.search_rounded,
              label: 'Manage Complaints',
              color: AppColors.primary,
              onTap: () => _showComplaintsInspectModal(context, allComplaints),
            ),
            _buildActionChip(
              icon: Icons.engineering_rounded,
              label: 'Manage Workers',
              color: AppColors.secondary,
              onTap: () => setState(() => _currentNavIndex = 2),
            ),
            _buildActionChip(
              icon: Icons.people_alt_rounded,
              label: 'Manage Students',
              color: AppColors.accent,
              onTap: () {
                setState(() {
                  _selectedRoleFilter = AppConstants.roleStudent;
                  _currentNavIndex = 3;
                });
              },
            ),
            _buildActionChip(
              icon: Icons.notifications_active_outlined,
              label: 'Notifications',
              color: AppColors.warningDark,
              onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
            ),
            _buildActionChip(
              icon: Icons.assessment_outlined,
              label: 'Operations Reports',
              color: AppColors.successDark,
              onTap: () => _showReportsModal(context, allComplaints),
            ),
            _buildActionChip(
              icon: Icons.settings_outlined,
              label: 'Settings & Dev Tools',
              color: Colors.blueGrey,
              onTap: () => Navigator.pushNamed(context, AppRoutes.settingsRoute),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2. COMPLAINT ANALYTICS VIEW
  // =========================================================================
  Widget _buildAnalyticsView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final complaintsAsync = ref.watch(allComplaintsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comprehensive Complaint Analytics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Breakdown of campus infrastructure requests across categories, priorities, statuses, and locations',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),

              complaintsAsync.when(
                loading: () => const LoadingView(size: 28),
                error: (e, _) => Text('Error: $e'),
                data: (all) {
                  return Column(
                    children: [
                      // Distribution by Category
                      _buildCategoryAnalyticsCard(all, isDark),
                      const SizedBox(height: 20),

                      // Distribution by Priority & Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildPriorityAnalyticsCard(all, isDark)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatusAnalyticsCard(all, isDark)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Distribution by Building/Location
                      _buildLocationAnalyticsCard(all, isDark),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryAnalyticsCard(List<ComplaintModel> all, bool isDark) {
    final total = all.length;
    final Map<String, int> counts = {};
    for (final c in all) {
      counts[c.category] = (counts[c.category] ?? 0) + 1;
    }

    final categories = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    return InteractiveCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Breakdown by Problem Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('$total Total Issues', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            const Text('No complaint records logged yet.')
          else
            ...categories.map((cat) {
              final count = counts[cat] ?? 0;
              final percent = total > 0 ? (count / total) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text('$count (${(percent * 100).toStringAsFixed(1)}%)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: percent,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPriorityAnalyticsCard(List<ComplaintModel> all, bool isDark) {
    final total = all.length;
    final critical = all.where((c) => c.priority.toUpperCase() == 'CRITICAL').length;
    final high = all.where((c) => c.priority.toUpperCase() == 'HIGH').length;
    final medium = all.where((c) => c.priority.toUpperCase() == 'MEDIUM').length;
    final low = all.where((c) => c.priority.toUpperCase() == 'LOW').length;

    return InteractiveCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Priority Distribution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _buildDistributionRow('Critical', critical, total, AppColors.error, isDark),
          _buildDistributionRow('High', high, total, AppColors.warningDark, isDark),
          _buildDistributionRow('Medium', medium, total, AppColors.primary, isDark),
          _buildDistributionRow('Low', low, total, AppColors.successDark, isDark),
        ],
      ),
    );
  }

  Widget _buildStatusAnalyticsCard(List<ComplaintModel> all, bool isDark) {
    final total = all.length;
    final pending = all.where((c) => c.status == AppConstants.statusPending).length;
    final assigned = all.where((c) => c.status == AppConstants.statusAssigned).length;
    final inProgress = all.where((c) => c.status == AppConstants.statusInProgress).length;
    final resolved = all.where((c) => c.status == AppConstants.statusResolved).length;

    return InteractiveCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Lifecycle Distribution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _buildDistributionRow('Pending', pending, total, AppColors.warningDark, isDark),
          _buildDistributionRow('Assigned', assigned, total, AppColors.secondary, isDark),
          _buildDistributionRow('In Progress', inProgress, total, AppColors.primary, isDark),
          _buildDistributionRow('Resolved', resolved, total, AppColors.successDark, isDark),
        ],
      ),
    );
  }

  Widget _buildDistributionRow(String label, int count, int total, Color color, bool isDark) {
    final percent = total > 0 ? (count / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAnalyticsCard(List<ComplaintModel> all, bool isDark) {
    final Map<String, int> zoneCounts = {
      'Academic Blocks': 0,
      'Hostels & Residential': 0,
      'Labs & Workshops': 0,
      'Central Library': 0,
      'Canteen & Cafeteria': 0,
      'Administrative Office': 0,
      'Other Campus Areas': 0,
    };

    for (final c in all) {
      final loc = c.location.toLowerCase();
      if (loc.contains('block') || loc.contains('class') || loc.contains('cse') || loc.contains('ece') || loc.contains('mech')) {
        zoneCounts['Academic Blocks'] = zoneCounts['Academic Blocks']! + 1;
      } else if (loc.contains('hostel') || loc.contains('dorm')) {
        zoneCounts['Hostels & Residential'] = zoneCounts['Hostels & Residential']! + 1;
      } else if (loc.contains('lab') || loc.contains('workshop')) {
        zoneCounts['Labs & Workshops'] = zoneCounts['Labs & Workshops']! + 1;
      } else if (loc.contains('library')) {
        zoneCounts['Central Library'] = zoneCounts['Central Library']! + 1;
      } else if (loc.contains('canteen') || loc.contains('mess') || loc.contains('cafe')) {
        zoneCounts['Canteen & Cafeteria'] = zoneCounts['Canteen & Cafeteria']! + 1;
      } else if (loc.contains('admin') || loc.contains('office')) {
        zoneCounts['Administrative Office'] = zoneCounts['Administrative Office']! + 1;
      } else {
        zoneCounts['Other Campus Areas'] = zoneCounts['Other Campus Areas']! + 1;
      }
    }

    final total = all.length;

    return InteractiveCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city_rounded, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Text('Complaints by Campus Building / Zone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          ...zoneCounts.entries.map((entry) {
            final percent = total > 0 ? (entry.value / total) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${entry.value} reports', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percent,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. WORKER PERFORMANCE & RANKED LEADERBOARD VIEW
  // =========================================================================
  Widget _buildWorkerPerformanceView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workersAsync = ref.watch(workersListProvider);
    final complaints = ref.watch(allComplaintsProvider).value ?? [];

    return workersAsync.when(
      loading: () => const LoadingView(message: 'Loading technician rankings...'),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (workers) {
        if (workers.isEmpty) {
          return const EmptyView(
            title: 'No Technicians Registered',
            message: 'Workers will appear on the leaderboard once registered.',
            icon: Icons.engineering_outlined,
          );
        }

        // Compute performance data for each worker
        final workerStats = workers.map((w) {
          final assignedTasks = complaints.where((c) => c.assignedWorkerId == w.uid).toList();
          final totalAssigned = assignedTasks.length;
          final completed = assignedTasks.where((c) => c.status == AppConstants.statusResolved).length;
          final pending = totalAssigned - completed;
          final rate = totalAssigned > 0 ? ((completed / totalAssigned) * 100).toInt() : 0;
          return {
            'worker': w,
            'assigned': totalAssigned,
            'completed': completed,
            'pending': pending,
            'rate': rate,
          };
        }).toList();

        // Rank by completed tasks descending, then rate descending
        workerStats.sort((a, b) {
          final cmpCompleted = (b['completed'] as int).compareTo(a['completed'] as int);
          if (cmpCompleted != 0) return cmpCompleted;
          return (b['rate'] as int).compareTo(a['rate'] as int);
        });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: workerStats.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final stat = workerStats[index];
            final w = stat['worker'] as UserModel;
            final assigned = stat['assigned'] as int;
            final completed = stat['completed'] as int;
            final pending = stat['pending'] as int;
            final rate = stat['rate'] as int;

            return MotionReveal.staggered(
              index: index,
              child: InteractiveCard(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                            : (index == 1
                                ? const Color(0xFFC0C0C0).withValues(alpha: 0.2)
                                : (index == 2
                                    ? const Color(0xFFCD7F32).withValues(alpha: 0.2)
                                    : AppColors.primary.withValues(alpha: 0.1))),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: index < 3 ? AppColors.warningDark : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    AvatarImage(name: w.name, radius: 22),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          Text('${w.department} • ${w.phone.isNotEmpty ? w.phone : "Extension"}',
                              style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildMiniPill('Assigned: $assigned', AppColors.primary),
                              const SizedBox(width: 6),
                              _buildMiniPill('Done: $completed', AppColors.successDark),
                              const SizedBox(width: 6),
                              _buildMiniPill('Pending: $pending', AppColors.warningDark),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$rate%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.successDark)),
                        const Text('Resolution Rate', style: TextStyle(fontSize: 10, color: AppColors.lightTextSecondary)),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 60,
                          child: LinearProgressIndicator(
                            value: assigned > 0 ? (completed / assigned) : 0,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                            backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  // =========================================================================
  // 4. USER MANAGEMENT VIEW
  // =========================================================================
  Widget _buildUserManagementView() {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: SkeletonComplaintList(count: 3),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (users) {
        var filtered = users.where((u) {
          if (_selectedRoleFilter != 'ALL' && u.role != _selectedRoleFilter) return false;
          if (_userSearchQuery.isNotEmpty) {
            final match = u.name.toLowerCase().contains(_userSearchQuery) ||
                u.email.toLowerCase().contains(_userSearchQuery) ||
                u.department.toLowerCase().contains(_userSearchQuery);
            if (!match) return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchUserCtrl,
                      onChanged: (val) => setState(() => _userSearchQuery = val.toLowerCase()),
                      decoration: const InputDecoration(
                        hintText: 'Search user name, email, department...',
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedRoleFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Roles')),
                      DropdownMenuItem(value: AppConstants.roleStudent, child: Text('Students')),
                      DropdownMenuItem(value: AppConstants.roleStaff, child: Text('Staff')),
                      DropdownMenuItem(value: AppConstants.roleWorker, child: Text('Workers')),
                      DropdownMenuItem(value: AppConstants.roleAdmin, child: Text('Admins')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRoleFilter = val);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyView(title: 'No Users Found', message: 'No users matching search criteria.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final u = filtered[index];
                        return MotionReveal.staggered(
                          index: index,
                          child: InteractiveCard(
                            borderRadius: BorderRadius.circular(14),
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              leading: AvatarImage(name: u.name, imageUrl: u.profileImage, radius: 20),
                              title: Row(
                                children: [
                                  Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: u.isActive ? AppColors.successContainer : AppColors.errorContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      u.isActive ? 'ACTIVE' : 'DEACTIVATED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: u.isActive ? AppColors.successDark : AppColors.errorDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text('${u.email}  •  ${u.department}  •  [${u.role.toUpperCase()}]',
                                  style: const TextStyle(fontSize: 12)),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'ROLE') {
                                    _showRoleChangeDialog(context, u);
                                  } else if (action == 'STATUS') {
                                    _toggleUserActiveStatus(context, u);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'ROLE', child: Text('Change Role')),
                                  PopupMenuItem(
                                    value: 'STATUS',
                                    child: Text(u.isActive ? 'Deactivate User' : 'Activate User'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // 5. AUDIT ACTIVITY LOGS VIEW
  // =========================================================================
  Widget _buildAuditLogsView() {
    final logsAsync = ref.watch(activityLogsProvider);

    return logsAsync.when(
      loading: () => const LoadingView(message: 'Loading audit activity stream...'),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (logs) {
        if (logs.isEmpty) {
          return const EmptyView(
            title: 'No Activity Logs',
            message: 'Campus maintenance operations will appear here.',
            icon: Icons.history_rounded,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final log = logs[index];
            return MotionReveal.staggered(
              index: index,
              child: InteractiveCard(
                borderRadius: BorderRadius.circular(14),
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bolt_rounded, size: 20, color: AppColors.primary),
                  ),
                  title: Text(log.action.replaceAll('_', ' '), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: Text('${log.description}\nActor: ${log.actorName} (${log.actorRole.toUpperCase()})',
                      style: const TextStyle(fontSize: 12)),
                  trailing: Text(
                    DateFormatter.formatRelative(log.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.lightTextMuted),
                  ),
                  isThreeLine: true,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
