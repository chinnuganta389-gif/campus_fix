import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../services/providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'complaint_submitted':
        return Icons.assignment_turned_in_rounded;
      case 'complaint_assigned':
        return Icons.person_search_rounded;
      case 'work_started':
        return Icons.engineering_rounded;
      case 'complaint_resolved':
        return Icons.check_circle_rounded;
      case 'complaint_rejected':
        return Icons.cancel_rounded;
      case 'announcement':
      default:
        return Icons.campaign_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'complaint_submitted':
        return AppColors.primary;
      case 'complaint_assigned':
        return AppColors.info;
      case 'work_started':
        return AppColors.warning;
      case 'complaint_resolved':
        return AppColors.success;
      case 'complaint_rejected':
        return AppColors.error;
      case 'announcement':
      default:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final user = ref.watch(currentUserProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              if (user != null) {
                final firestore = ref.read(firestoreServiceProvider);
                await firestore.markAllNotificationsAsRead(user.uid);
              }
            },
            child: const Text('Mark all read'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingView(message: 'Loading notifications...'),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyView(
              title: 'No Notifications',
              message: 'You have no notifications at the moment.',
              icon: Icons.notifications_none_rounded,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final icon = _getNotificationIcon(notif.type);
              final color = _getNotificationColor(notif.type);

              return Card(
                color: notif.isRead
                    ? (isDark ? AppColors.darkCard : Colors.white)
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    if (!notif.isRead) {
                      await ref.read(firestoreServiceProvider).markNotificationAsRead(notif.id);
                    }
                    if (notif.complaintId != null && notif.complaintId!.isNotEmpty) {
                      final comp = await ref.read(firestoreServiceProvider).getComplaint(notif.complaintId!);
                      if (comp != null && context.mounted) {
                        Navigator.pushNamed(context, AppRoutes.complaintDetail, arguments: comp);
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    DateFormatter.formatRelative(notif.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!notif.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
