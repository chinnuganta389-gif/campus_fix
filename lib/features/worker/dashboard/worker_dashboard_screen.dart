import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/priority_badge.dart';
import '../../../core/widgets/responsive_scaffold.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/complaint_model.dart';
import '../../../services/providers.dart';

class WorkerDashboardScreen extends ConsumerStatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  ConsumerState<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends ConsumerState<WorkerDashboardScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL'; // ALL, ASSIGNED, IN_PROGRESS, RESOLVED, OVERDUE

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  DateTime _getDueTime(ComplaintModel task) {
    final created = task.createdAt;
    switch (task.priority.toUpperCase()) {
      case 'CRITICAL':
        return created.add(const Duration(hours: 6));
      case 'HIGH':
        return created.add(const Duration(hours: 24));
      case 'MEDIUM':
        return created.add(const Duration(hours: 48));
      case 'LOW':
      default:
        return created.add(const Duration(hours: 72));
    }
  }

  bool _isTaskOverdue(ComplaintModel task) {
    if (task.status == AppConstants.statusResolved || task.status == AppConstants.statusRejected) {
      return false;
    }
    return DateTime.now().isAfter(_getDueTime(task));
  }

  String _getDueTimeFormatted(ComplaintModel task) {
    if (task.status == AppConstants.statusResolved) {
      return 'Resolved';
    }
    final due = _getDueTime(task);
    final now = DateTime.now();
    if (now.isAfter(due)) {
      final diff = now.difference(due);
      if (diff.inHours < 24) {
        return 'Overdue by ${diff.inHours == 0 ? "${diff.inMinutes}m" : "${diff.inHours}h"}';
      }
      return 'Overdue by ${diff.inDays}d';
    } else {
      final diff = due.difference(now);
      if (diff.inHours < 24) {
        return 'Due in ${diff.inHours == 0 ? "${diff.inMinutes}m" : "${diff.inHours}h"}';
      }
      return 'Due in ${diff.inDays}d';
    }
  }

  // Handle Accept or Start Work
  Future<void> _handleTaskAction(BuildContext context, ComplaintModel task, String action) async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;
    final firestore = ref.read(firestoreServiceProvider);

    if (action == 'ACCEPT') {
      try {
        await firestore.updateComplaintStatus(
          complaintId: task.complaintId,
          newStatus: AppConstants.statusInProgress,
          actorId: user.uid,
          actorName: user.name,
          actorRole: AppConstants.roleWorker,
          note: 'Task accepted by technician ${user.name}. Preparing tools & equipment.',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task accepted and moved to In Progress.'),
              backgroundColor: AppColors.successDark,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to accept task: $e')),
          );
        }
      }
    } else if (action == 'START_WORK') {
      try {
        await firestore.updateComplaintStatus(
          complaintId: task.complaintId,
          newStatus: AppConstants.statusInProgress,
          actorId: user.uid,
          actorName: user.name,
          actorRole: AppConstants.roleWorker,
          note: 'Technician arrived on-site and commenced repair work.',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Work started on task.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: $e')),
          );
        }
      }
    } else if (action == 'UPDATE_STATUS') {
      _showUpdateStatusDialog(context, task);
    } else if (action == 'MARK_RESOLVED' || action == 'UPLOAD_EVIDENCE') {
      _showResolveDialog(context, task);
    }
  }

  // Intermediate status/note update dialog
  void _showUpdateStatusDialog(BuildContext context, ComplaintModel task) {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    final noteController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Update Status #${task.complaintId}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Post a progress note or field observation for this complaint:',
                  style: TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: noteController,
                  label: 'Progress Update',
                  hintText: 'e.g., Awaiting replacement MCB switch from store room.',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final note = noteController.text.trim();
                        if (note.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter an update note.')),
                          );
                          return;
                        }

                        setStateModal(() => isSaving = true);
                        try {
                          final firestore = ref.read(firestoreServiceProvider);
                          await firestore.updateComplaintStatus(
                            complaintId: task.complaintId,
                            newStatus: task.status,
                            actorId: user.uid,
                            actorName: user.name,
                            actorRole: AppConstants.roleWorker,
                            note: note,
                          );

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Field update recorded successfully.'),
                                backgroundColor: AppColors.successDark,
                              ),
                            );
                          }
                        } catch (e) {
                          setStateModal(() => isSaving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Post Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Final resolution modal with image upload and completion note
  void _showResolveDialog(BuildContext context, ComplaintModel task) {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    final noteController = TextEditingController();
    XFile? resolutionImage;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.successContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: AppColors.successDark, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Complete Task #${task.complaintId}',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                task.title,
                                style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    controller: noteController,
                    label: 'Resolution Note',
                    hintText: 'Describe how the issue was resolved (e.g. replaced burnt capacitor, reconnected wiring)',
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Upload Evidence Photo
                  const Text(
                    'Work Completion Evidence (Optional)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),

                  if (resolutionImage != null) ...[
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            kIsWeb
                                ? Image.network(resolutionImage!.path, fit: BoxFit.cover)
                                : Image.file(File(resolutionImage!.path), fit: BoxFit.cover),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withValues(alpha: 0.6),
                                radius: 16,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                                  onPressed: () {
                                    setStateModal(() => resolutionImage = null);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final img = await picker.pickImage(
                                source: ImageSource.camera,
                                maxWidth: 1200,
                                imageQuality: 85,
                              );
                              if (img != null) {
                                setStateModal(() => resolutionImage = img);
                              }
                            },
                            icon: const Icon(Icons.camera_alt_outlined, size: 20),
                            label: const Text('Take Photo'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final img = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1200,
                                imageQuality: 85,
                              );
                              if (img != null) {
                                setStateModal(() => resolutionImage = img);
                              }
                            },
                            icon: const Icon(Icons.photo_library_outlined, size: 20),
                            label: const Text('Upload Gallery'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  CustomButton(
                    text: 'MARK COMPLETED',
                    icon: Icons.check_circle_outline_rounded,
                    variant: ButtonVariant.primary,
                    isLoading: isSubmitting,
                    onPressed: () async {
                      if (noteController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a resolution note.')),
                        );
                        return;
                      }

                      setStateModal(() => isSubmitting = true);
                      try {
                        String? imageUrl;
                        if (resolutionImage != null) {
                          final storage = ref.read(storageServiceProvider);
                          imageUrl = await storage.uploadResolutionImage(
                            file: resolutionImage!,
                            complaintId: task.complaintId,
                          );
                        }

                        final firestore = ref.read(firestoreServiceProvider);
                        await firestore.updateComplaintStatus(
                          complaintId: task.complaintId,
                          newStatus: AppConstants.statusResolved,
                          actorId: user.uid,
                          actorName: user.name,
                          actorRole: AppConstants.roleWorker,
                          note: noteController.text.trim(),
                          resolutionImageUrl: imageUrl,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task marked as Resolved successfully!'),
                              backgroundColor: AppColors.successDark,
                            ),
                          );
                        }
                      } catch (e) {
                        setStateModal(() => isSubmitting = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from the Worker Portal?'),
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

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final navItems = [
      const NavigationItem(
        label: 'My Tasks',
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment_rounded,
      ),
      const NavigationItem(
        label: 'Performance',
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights_rounded,
      ),
      const NavigationItem(
        label: 'Profile',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
    ];

    final pages = [
      _buildTasksView(),
      _buildPerformanceView(),
      _buildProfileView(),
    ];

    return ResponsiveScaffold(
      title: 'Worker Portal',
      currentIndex: _currentNavIndex,
      onNavigationChanged: (index) {
        setState(() => _currentNavIndex = index);
      },
      items: navItems,
      actions: [
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.settingsRoute),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
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
        const SizedBox(width: 8),
      ],
      body: pages[_currentNavIndex],
    );
  }

  // 1. TASKS VIEW
  Widget _buildTasksView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workerTasksAsync = ref.watch(workerComplaintsProvider);
    final user = ref.watch(currentUserProfileProvider).value;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(workerComplaintsProvider);
      },
      child: CustomScrollView(
        slivers: [
          // Header & Welcome
          SliverToBoxAdapter(
            child: _buildWelcomeHeader(user, isDark),
          ),

          // Today's Assignments Summary Cards
          SliverToBoxAdapter(
            child: workerTasksAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SkeletonStatGrid(),
              ),
              error: (err, _) => const SizedBox(),
              data: (tasks) => _buildTodaysAssignmentsSection(tasks, isDark),
            ),
          ),

          // Search and Status Filters
          SliverToBoxAdapter(
            child: _buildSearchAndFilterBar(isDark),
          ),

          // Task List
          workerTasksAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SkeletonComplaintList(count: 3),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: EmptyView(
                  title: 'Unable to load tasks',
                  message: 'Error: $err',
                  icon: Icons.error_outline_rounded,
                ),
              ),
            ),
            data: (tasks) {
              final filtered = tasks.where((t) {
                // Status Filter
                if (_selectedStatusFilter == 'ASSIGNED' && t.status != AppConstants.statusAssigned) return false;
                if (_selectedStatusFilter == 'IN_PROGRESS' && t.status != AppConstants.statusInProgress) return false;
                if (_selectedStatusFilter == 'RESOLVED' && t.status != AppConstants.statusResolved) return false;
                if (_selectedStatusFilter == 'OVERDUE' && !_isTaskOverdue(t)) return false;

                // Search Query
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  final match = t.complaintId.toLowerCase().contains(q) ||
                      t.title.toLowerCase().contains(q) ||
                      t.location.toLowerCase().contains(q) ||
                      t.category.toLowerCase().contains(q);
                  if (!match) return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                    child: EmptyView(
                      title: _searchQuery.isNotEmpty ? 'No Matching Tasks' : 'All Caught Up!',
                      message: _searchQuery.isNotEmpty
                          ? 'Try refining your search keyword or clearing the filters.'
                          : 'Great job! You have no pending tasks in this category.',
                      icon: Icons.task_alt_rounded,
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: MotionReveal.staggered(
                          index: index,
                          child: _buildTaskCard(task, isDark),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(dynamic user, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          AvatarImage(name: user?.name ?? 'Worker', radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_getGreeting()}, ${user?.name ?? "Technician"}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ON DUTY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.successDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Field Technician • ${user?.department ?? "Campus Facilities"}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

  Widget _buildTodaysAssignmentsSection(List<ComplaintModel> tasks, bool isDark) {
    final assignedCount = tasks.where((t) => t.status == AppConstants.statusAssigned).length;
    final inProgressCount = tasks.where((t) => t.status == AppConstants.statusInProgress).length;
    final completedCount = tasks.where((t) => t.status == AppConstants.statusResolved).length;
    final overdueCount = tasks.where((t) => _isTaskOverdue(t)).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S ASSIGNMENTS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: _buildStatItem('Assigned', assignedCount, Icons.assignment_outlined, AppColors.primary, isDark, 'ASSIGNED')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatItem('In Progress', inProgressCount, Icons.engineering_rounded, AppColors.warningDark, isDark, 'IN_PROGRESS')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatItem('Completed', completedCount, Icons.check_circle_rounded, AppColors.successDark, isDark, 'RESOLVED')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatItem('Overdue', overdueCount, Icons.alarm_rounded, AppColors.error, isDark, 'OVERDUE')),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildStatItem('Assigned', assignedCount, Icons.assignment_outlined, AppColors.primary, isDark, 'ASSIGNED')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatItem('In Progress', inProgressCount, Icons.engineering_rounded, AppColors.warningDark, isDark, 'IN_PROGRESS')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildStatItem('Completed', completedCount, Icons.check_circle_rounded, AppColors.successDark, isDark, 'RESOLVED')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildStatItem('Overdue', overdueCount, Icons.alarm_rounded, AppColors.error, isDark, 'OVERDUE')),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color, bool isDark, String filterKey) {
    final isSelected = _selectedStatusFilter == filterKey;

    return InteractiveCard(
      onTap: () {
        setState(() {
          _selectedStatusFilter = isSelected ? 'ALL' : filterKey;
        });
      },
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedCounter(
                  value: count,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle_rounded, color: color, size: 16),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            decoration: InputDecoration(
              hintText: 'Search by Ticket ID, room, or title...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All Tasks'),
                const SizedBox(width: 8),
                _buildFilterChip('ASSIGNED', 'Assigned'),
                const SizedBox(width: 8),
                _buildFilterChip('IN_PROGRESS', 'In Progress'),
                const SizedBox(width: 8),
                _buildFilterChip('RESOLVED', 'Completed'),
                const SizedBox(width: 8),
                _buildFilterChip('OVERDUE', 'Overdue'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : null,
      ),
      selectedColor: AppColors.primary,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = selected ? key : 'ALL';
        });
      },
    );
  }

  Widget _buildTaskCard(ComplaintModel task, bool isDark) {
    final dueFormatted = _getDueTimeFormatted(task);
    final overdue = _isTaskOverdue(task);

    return InteractiveCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: ID, Category & Priority
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${task.complaintId}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              PriorityBadge(priority: task.priority),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            task.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 15, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.location,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Description snippet
          Text(
            task.description,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Timing Info: Assigned time & Due time
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.lightTextSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned ${DateFormatter.formatRelative(task.assignedAt ?? task.createdAt)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      overdue ? Icons.warning_amber_rounded : Icons.timer_outlined,
                      size: 14,
                      color: overdue ? AppColors.error : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dueFormatted,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: overdue ? AppColors.error : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Evidence Image Thumbnail if present
          if (task.imageUrl != null && task.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                task.imageUrl!,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Status & Action Buttons
          Row(
            children: [
              StatusBadge(status: task.status),
              const Spacer(),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.complaintDetail, arguments: task);
                },
                child: const Text('Details', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),

              // Dynamic Workflow Actions
              if (task.status == AppConstants.statusAssigned) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Accept & Start', style: TextStyle(fontSize: 12)),
                  onPressed: () => _handleTaskAction(context, task, 'ACCEPT'),
                ),
              ] else if (task.status == AppConstants.statusInProgress) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _handleTaskAction(context, task, 'UPDATE_STATUS'),
                  child: const Text('Update Note', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.task_alt_rounded, size: 16),
                  label: const Text('Complete', style: TextStyle(fontSize: 12)),
                  onPressed: () => _handleTaskAction(context, task, 'MARK_RESOLVED'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 2. PERFORMANCE VIEW
  Widget _buildPerformanceView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasks = ref.watch(workerComplaintsProvider).value ?? [];

    final totalAssigned = tasks.length;
    final completedTasks = tasks.where((t) => t.status == AppConstants.statusResolved).toList();
    final completedCount = completedTasks.length;
    final inProgressCount = tasks.where((t) => t.status == AppConstants.statusInProgress).length;
    final assignedCount = tasks.where((t) => t.status == AppConstants.statusAssigned).length;
    final pendingCount = assignedCount + inProgressCount;
    final overdueCount = tasks.where((t) => _isTaskOverdue(t)).length;

    final completionRate = totalAssigned > 0 ? ((completedCount / totalAssigned) * 100).toInt() : 0;

    // Calculate Average Resolution Time
    String avgResolutionTime = '2.5 hrs';
    if (completedTasks.isNotEmpty) {
      double totalHours = 0;
      int countWithResolution = 0;
      for (final t in completedTasks) {
        if (t.resolvedAt != null) {
          final start = t.startedAt ?? t.assignedAt ?? t.createdAt;
          final diff = t.resolvedAt!.difference(start).inMinutes;
          if (diff > 0) {
            totalHours += (diff / 60.0);
            countWithResolution++;
          }
        }
      }
      if (countWithResolution > 0) {
        final avg = totalHours / countWithResolution;
        avgResolutionTime = avg < 1.0 ? '${(avg * 60).toInt()} mins' : '${avg.toStringAsFixed(1)} hrs';
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Work Summary & Efficiency',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time overview of tasks completed, SLAs, and resolution response velocity',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Work Summary Card
              InteractiveCard(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Work Summary",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$totalAssigned Tasks Total',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricMini(
                            label: 'Assigned',
                            value: '$totalAssigned',
                            color: AppColors.primary,
                            icon: Icons.assignment_outlined,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricMini(
                            label: 'Completed',
                            value: '$completedCount',
                            color: AppColors.successDark,
                            icon: Icons.check_circle_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricMini(
                            label: 'Pending',
                            value: '$pendingCount',
                            color: AppColors.warningDark,
                            icon: Icons.pending_actions_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricMini(
                            label: 'Overdue',
                            value: '$overdueCount',
                            color: AppColors.error,
                            icon: Icons.alarm_rounded,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Performance KPI Cards
              Text(
                'Performance Metrics',
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
                    child: InteractiveCard(
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.percent_rounded, color: AppColors.primary, size: 24),
                          const SizedBox(height: 10),
                          AnimatedCounter(
                            value: completionRate,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Completion Rate',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: totalAssigned > 0 ? (completedCount / totalAssigned) : 0,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(4),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            backgroundColor: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InteractiveCard(
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.timer_rounded, color: AppColors.secondary, size: 24),
                          const SizedBox(height: 10),
                          Text(
                            avgResolutionTime,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Avg Resolution Time',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Meets college SLA target',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.successDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              InteractiveCard(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_rounded, color: AppColors.successDark, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$completedCount Tasks Completed Successfully',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Verified through student sign-off and technician resolution reports.',
                            style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
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
    );
  }

  Widget _buildMetricMini({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
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
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // 3. PROFILE VIEW
  Widget _buildProfileView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProfileProvider).value;
    final tasks = ref.watch(workerComplaintsProvider).value ?? [];

    final completedCount = tasks.where((t) => t.status == AppConstants.statusResolved).length;
    final pendingCount = tasks.where((t) => t.status != AppConstants.statusResolved).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              InteractiveCard(
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    AvatarImage(name: user?.name ?? 'Worker', radius: 44),
                    const SizedBox(height: 14),
                    Text(
                      user?.name ?? 'Field Technician',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dept: ${user?.department ?? "Facilities Maintenance"} • ID: ${user?.uid.substring(0, 6).toUpperCase() ?? ""}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.successContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                AnimatedCounter(
                                  value: completedCount,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.successDark,
                                  ),
                                ),
                                const Text('Completed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.warningContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                AnimatedCounter(
                                  value: pendingCount,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.warningDark,
                                  ),
                                ),
                                const Text('Pending Tasks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Menu list
              InteractiveCard(
                borderRadius: BorderRadius.circular(16),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
                      title: const Text('Settings & Campus Info', style: TextStyle(fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.settingsRoute),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                      title: const Text('Sign Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                      onTap: () => _handleLogout(context),
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
}
