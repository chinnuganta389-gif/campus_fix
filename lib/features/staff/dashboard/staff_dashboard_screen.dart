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
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/responsive_scaffold.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/complaint_model.dart';
import '../../../models/user_model.dart';
import '../../../services/providers.dart';

class StaffDashboardScreen extends ConsumerStatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  ConsumerState<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends ConsumerState<StaffDashboardScreen> {
  int _currentNavIndex = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeSectionFilter = 'ALL'; // ALL, PRIORITY, UNASSIGNED, OVERDUE

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAssignWorkerDialog(BuildContext context, ComplaintModel complaint) {
    final workersAsync = ref.read(workersListProvider);
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    UserModel? selectedWorker;
    String selectedPriority = complaint.priority;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            title: Text('Assign Worker - #${complaint.complaintId}'),
            content: workersAsync.when(
              loading: () => const LoadingView(size: 24),
              error: (err, _) => Text('Error loading workers: $err'),
              data: (workers) {
                if (workers.isEmpty) {
                  return const Text('No active technicians registered in the system.');
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Technician:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<UserModel>(
                      initialValue: selectedWorker,
                      hint: const Text('Choose Worker'),
                      items: workers.map((w) {
                        return DropdownMenuItem(
                          value: w,
                          child: Text('${w.name} (${w.department})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateModal(() => selectedWorker = val);
                      },
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Set Priority:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPriority,
                      items: AppConstants.allPriorities.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setStateModal(() => selectedPriority = val);
                      },
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: (selectedWorker == null || isSaving)
                    ? null
                    : () async {
                        setStateModal(() => isSaving = true);
                        try {
                          final firestore = ref.read(firestoreServiceProvider);
                          await firestore.assignWorker(
                            complaintId: complaint.complaintId,
                            workerId: selectedWorker!.uid,
                            workerName: selectedWorker!.name,
                            actorId: user.uid,
                            actorName: user.name,
                            actorRole: user.role,
                            priority: selectedPriority,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Assigned #${complaint.complaintId} to ${selectedWorker!.name}.')),
                            );
                          }
                        } catch (e) {
                          setStateModal(() => isSaving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Failed: $e')),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOperationsReportModal(BuildContext context, List<ComplaintModel> all) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = all.length;
    final resolved = all.where((c) => c.status == AppConstants.statusResolved).length;
    final pending = all.where((c) => c.status == AppConstants.statusPending).length;
    final inProgress = all.where((c) => c.status == AppConstants.statusInProgress || c.status == AppConstants.statusAssigned).length;
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
                const Text('Operations Summary Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            Text('LBRCE Campus Maintenance Efficiency: $rate% resolution rate',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 16),
            _buildReportRow('Total Requests Received', '$total', isDark),
            _buildReportRow('Successfully Resolved', '$resolved', isDark),
            _buildReportRow('In Progress / Assigned', '$inProgress', isDark),
            _buildReportRow('Awaiting Review', '$pending', isDark),
            const SizedBox(height: 20),
            CustomButton(text: 'Close', onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final navItems = [
      const NavigationItem(
        label: 'Operations',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
      ),
      const NavigationItem(
        label: 'Complaints',
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment_rounded,
      ),
      const NavigationItem(
        label: 'Technicians',
        icon: Icons.engineering_outlined,
        selectedIcon: Icons.engineering_rounded,
      ),
      const NavigationItem(
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
    ];

    final pages = [
      _buildOperationsView(),
      _buildComplaintManagementView(),
      _buildTechniciansView(),
      _buildProfileView(),
    ];

    return ResponsiveScaffold(
      title: 'CampusFix • Staff Console',
      showAppBar: true,
      currentIndex: _currentNavIndex,
      onNavigationChanged: (index) {
        setState(() {
          _currentNavIndex = index;
        });
      },
      items: navItems,
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settingsRoute),
        ),
        const SizedBox(width: 8),
      ],
      body: pages[_currentNavIndex],
    );
  }

  // 1. OPERATIONS DASHBOARD VIEW
  Widget _buildOperationsView() {
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
              // Header Title
              MotionReveal.staggered(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campus Operations Hub',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Real-time maintenance monitoring for LBRCE Campus facilities',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // TOP STATISTICS (6 KPI Cards)
              complaintsAsync.when(
                loading: () => const SkeletonStatGrid(),
                error: (err, _) => Text('Error loading stats: $err'),
                data: (all) {
                  final total = all.length;
                  final newRequests = all.where((c) => DateTime.now().difference(c.createdAt).inHours < 24).length;
                  final pendingReview = all.where((c) => c.status == AppConstants.statusPending).length;
                  final assigned = all.where((c) => c.status == AppConstants.statusAssigned).length;
                  final inProgress = all.where((c) => c.status == AppConstants.statusInProgress).length;
                  final resolved = all.where((c) => c.status == AppConstants.statusResolved).length;

                  return MotionReveal.staggered(
                    index: 1,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: crossAxisCount == 3 ? 2.1 : 1.7,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildKpiCard('Total Complaints', total, Icons.assignment_outlined, AppColors.primary, isDark),
                            _buildKpiCard('New (24h)', newRequests, Icons.fiber_new_rounded, const Color(0xFF0D9488), isDark),
                            _buildKpiCard('Pending Review', pendingReview, Icons.schedule_rounded, AppColors.warning, isDark),
                            _buildKpiCard('Assigned', assigned, Icons.person_search_rounded, AppColors.info, isDark),
                            _buildKpiCard('In Progress', inProgress, Icons.engineering_rounded, const Color(0xFF8B5CF6), isDark),
                            _buildKpiCard('Resolved', resolved, Icons.check_circle_outline_rounded, AppColors.success, isDark),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),

              // PRIORITY OVERVIEW SECTION
              MotionReveal.staggered(
                index: 2,
                child: Text(
                  'Priority Overview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              complaintsAsync.when(
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
                data: (all) {
                  final critical = all.where((c) => c.priority == AppConstants.priorityUrgent).length;
                  final high = all.where((c) => c.priority == AppConstants.priorityHigh).length;
                  final medium = all.where((c) => c.priority == AppConstants.priorityMedium).length;
                  final low = all.where((c) => c.priority == AppConstants.priorityLow).length;

                  return MotionReveal.staggered(
                    index: 3,
                    child: Row(
                      children: [
                        Expanded(child: _buildPriorityPill('Critical', critical, AppColors.error, isDark)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildPriorityPill('High', high, Colors.orange.shade700, isDark)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildPriorityPill('Medium', medium, AppColors.primary, isDark)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildPriorityPill('Low', low, Colors.blueGrey, isDark)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),

              // TODAY'S WORK CARD
              complaintsAsync.when(
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
                data: (all) {
                  final now = DateTime.now();
                  final newToday = all.where((c) => c.createdAt.day == now.day && c.createdAt.month == now.month && c.createdAt.year == now.year).length;
                  final assignedToday = all.where((c) => c.assignedAt != null && c.assignedAt!.day == now.day && c.assignedAt!.month == now.month && c.assignedAt!.year == now.year).length;
                  final resolvedToday = all.where((c) => c.resolvedAt != null && c.resolvedAt!.day == now.day && c.resolvedAt!.month == now.month && c.resolvedAt!.year == now.year).length;
                  final overdue = all.where((c) => c.status != AppConstants.statusResolved && now.difference(c.createdAt).inHours > 48).length;

                  return MotionReveal.staggered(
                    index: 4,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.today_rounded, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Today's Work Summary",
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  ),
                                ],
                              ),
                              if (overdue > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(6)),
                                  child: Text('$overdue Overdue', style: const TextStyle(color: AppColors.errorDark, fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: _buildMetricCol('New Today', '$newToday', isDark)),
                              Expanded(child: _buildMetricCol('Assigned Today', '$assignedToday', isDark)),
                              Expanded(child: _buildMetricCol('Resolved Today', '$resolvedToday', isDark)),
                              Expanded(child: _buildMetricCol('Overdue (>48h)', '$overdue', isDark, isAlert: overdue > 0)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),

              // QUICK ACTIONS (5 buttons)
              MotionReveal.staggered(
                index: 5,
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              MotionReveal.staggered(
                index: 6,
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickBtn(
                        title: 'Review',
                        icon: Icons.rate_review_rounded,
                        color: AppColors.primary,
                        isDark: isDark,
                        onTap: () => setState(() => _currentNavIndex = 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickBtn(
                        title: 'Assign Worker',
                        icon: Icons.person_add_rounded,
                        color: const Color(0xFF0D9488),
                        isDark: isDark,
                        onTap: () {
                          setState(() {
                            _currentNavIndex = 1;
                            _activeSectionFilter = 'UNASSIGNED';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickBtn(
                        title: 'Technicians',
                        icon: Icons.engineering_rounded,
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                        onTap: () => setState(() => _currentNavIndex = 2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickBtn(
                        title: 'Notifications',
                        icon: Icons.notifications_active_rounded,
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickBtn(
                        title: 'Reports',
                        icon: Icons.summarize_rounded,
                        color: AppColors.primaryDark,
                        isDark: isDark,
                        onTap: () => _showOperationsReportModal(context, complaintsAsync.value ?? []),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, bool isDark, {bool isAlert = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isAlert ? AppColors.error : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityPill(String label, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          AnimatedCounter(
            value: count,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBtn({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InteractiveCard(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
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

  Widget _buildKpiCard(String label, int value, IconData icon, Color color, bool isDark) {
    return InteractiveCard(
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              AnimatedCounter(
                value: value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 2. COMPLAINT MANAGEMENT VIEW (Sections: Recent, Priority, Unassigned, Overdue)
  Widget _buildComplaintManagementView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final complaintsAsync = ref.watch(allComplaintsProvider);

    return complaintsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: SkeletonComplaintList(count: 3),
      ),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (all) {
        final now = DateTime.now();
        var filtered = all.where((c) {
          if (_activeSectionFilter == 'PRIORITY' && (c.priority != AppConstants.priorityUrgent && c.priority != AppConstants.priorityHigh)) {
            return false;
          }
          if (_activeSectionFilter == 'UNASSIGNED' && (c.assignedWorkerId != null && c.assignedWorkerId!.isNotEmpty)) {
            return false;
          }
          if (_activeSectionFilter == 'OVERDUE' && (c.status == AppConstants.statusResolved || now.difference(c.createdAt).inHours <= 48)) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final match = c.title.toLowerCase().contains(_searchQuery) ||
                c.complaintId.toLowerCase().contains(_searchQuery) ||
                c.location.toLowerCase().contains(_searchQuery) ||
                c.studentName.toLowerCase().contains(_searchQuery);
            if (!match) return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Section Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _buildSectionFilterChip('All Complaints', 'ALL'),
                  const SizedBox(width: 8),
                  _buildSectionFilterChip('Priority Issues', 'PRIORITY'),
                  const SizedBox(width: 8),
                  _buildSectionFilterChip('Unassigned', 'UNASSIGNED'),
                  const SizedBox(width: 8),
                  _buildSectionFilterChip('Overdue (>48h)', 'OVERDUE'),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search ID, title, student, location...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Complaint List
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyView(
                      title: 'No Matching Requests',
                      message: 'No complaints matching current section and search filters.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return MotionReveal.staggered(
                          index: index,
                          child: _buildStaffComplaintCard(item, isDark),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionFilterChip(String label, String value) {
    final isSelected = _activeSectionFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _activeSectionFilter = value);
        }
      },
    );
  }

  Widget _buildStaffComplaintCard(ComplaintModel item, bool isDark) {
    return InteractiveCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    item.complaintId,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  PriorityBadge(priority: item.priority),
                  const SizedBox(width: 8),
                  StatusBadge(status: item.status, isCompact: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${item.location} • Student: ${item.studentName}',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              const SizedBox(width: 4),
              Text(
                'Created: ${DateFormatter.formatRelative(item.createdAt)}  •  Technician: ${item.assignedWorkerName ?? "Unassigned"}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: item.assignedWorkerId != null ? AppColors.primary : AppColors.warningDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.complaintDetail, arguments: item);
                  },
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: Text(item.assignedWorkerId == null ? 'Assign Worker' : 'Reassign'),
                  onPressed: () => _showAssignWorkerDialog(context, item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. TECHNICIANS / WORKERS DIRECTORY VIEW
  Widget _buildTechniciansView() {
    final workersAsync = ref.watch(workersListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return workersAsync.when(
      loading: () => const LoadingView(size: 28),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (workers) {
        if (workers.isEmpty) {
          return const EmptyView(
            title: 'No Technicians Registered',
            message: 'Active worker profiles will appear here once added.',
            icon: Icons.engineering_outlined,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: workers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final w = workers[index];
            return InteractiveCard(
              borderRadius: BorderRadius.circular(14),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AvatarImage(name: w.name, radius: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                        const SizedBox(height: 2),
                        Text('${w.department} • ${w.phone.isNotEmpty ? w.phone : w.email}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.successContainer, borderRadius: BorderRadius.circular(6)),
                    child: const Text('Available', style: TextStyle(color: AppColors.successDark, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 4. PROFILE VIEW
  Widget _buildProfileView() {
    final user = ref.watch(currentUserProfileProvider).value;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarImage(name: user?.name ?? 'Staff', radius: 40),
              const SizedBox(height: 14),
              Text(user?.name ?? 'Facility Staff', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(user?.email ?? '', style: const TextStyle(fontSize: 13, color: AppColors.lightTextSecondary)),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Sign Out',
                variant: ButtonVariant.danger,
                onPressed: () => _handleLogout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
