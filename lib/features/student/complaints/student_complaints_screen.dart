import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/motion/interactive_card.dart';
import '../../../core/motion/motion_reveal.dart';
import '../../../core/motion/shimmer_loading.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/complaint_model.dart';
import '../../../services/providers.dart';

class StudentComplaintsScreen extends ConsumerStatefulWidget {
  const StudentComplaintsScreen({super.key});

  @override
  ConsumerState<StudentComplaintsScreen> createState() => _StudentComplaintsScreenState();
}

class _StudentComplaintsScreenState extends ConsumerState<StudentComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _tabs = ['All', 'Pending', 'In Progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final complaintsAsync = ref.watch(studentComplaintsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          isScrollable: false,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: complaintsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16.0),
          child: SkeletonComplaintList(count: 4),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (complaints) {
          return Column(
            children: [
              // Search & Category Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search title, ID, or location...',
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Category dropdown filter
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _selectedCategory != 'All'
                              ? AppColors.primaryContainer
                              : (isDark ? AppColors.darkCard : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedCategory != 'All'
                                ? AppColors.primary
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        child: Icon(
                          Icons.filter_list_rounded,
                          size: 20,
                          color: _selectedCategory != 'All'
                              ? AppColors.primary
                              : (isDark ? Colors.white : AppColors.lightTextSecondary),
                        ),
                      ),
                      onSelected: (cat) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      itemBuilder: (context) {
                        final items = <PopupMenuEntry<String>>[
                          const PopupMenuItem(value: 'All', child: Text('All Categories')),
                          const PopupMenuDivider(),
                        ];
                        for (final cat in AppConstants.categories) {
                          items.add(PopupMenuItem(
                            value: cat['name'] as String,
                            child: Row(
                              children: [
                                Icon(cat['icon'] as IconData, size: 18, color: cat['color'] as Color),
                                const SizedBox(width: 8),
                                Text(cat['name'] as String),
                              ],
                            ),
                          ));
                        }
                        return items;
                      },
                    ),
                  ],
                ),
              ),

              if (_selectedCategory != 'All')
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text('Category: $_selectedCategory'),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedCategory = 'All';
                        });
                      },
                    ),
                  ),
                ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildComplaintsList(complaints, null, isDark),
                    _buildComplaintsList(complaints, AppConstants.statusPending, isDark),
                    _buildComplaintsList(complaints, AppConstants.statusInProgress, isDark),
                    _buildComplaintsList(complaints, AppConstants.statusResolved, isDark),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildComplaintsList(List<ComplaintModel> list, String? statusFilter, bool isDark) {
    final filtered = list.where((c) {
      if (statusFilter != null) {
        if (statusFilter == AppConstants.statusInProgress) {
          if (c.status != AppConstants.statusInProgress && c.status != AppConstants.statusAssigned) {
            return false;
          }
        } else if (c.status != statusFilter) {
          return false;
        }
      }
      if (_selectedCategory != 'All' && c.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final matchTitle = c.title.toLowerCase().contains(_searchQuery);
        final matchId = c.complaintId.toLowerCase().contains(_searchQuery);
        final matchLoc = c.location.toLowerCase().contains(_searchQuery);
        if (!matchTitle && !matchId && !matchLoc) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return EmptyView(
        title: 'No Complaints Found',
        message: statusFilter == null
            ? "You haven't reported any issues yet."
            : 'No complaints in "$statusFilter" status matching your filters.',
        icon: Icons.assignment_outlined,
        buttonText: statusFilter == null ? 'Report a Problem' : null,
        onButtonPressed: statusFilter == null
            ? () {
                Navigator.pushNamed(context, AppRoutes.reportProblem);
              }
            : null,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return MotionReveal.staggered(
          index: index,
          child: _buildComplaintCard(item, isDark),
        );
      },
    );
  }

  Widget _buildComplaintCard(ComplaintModel item, bool isDark) {
    final catData = AppConstants.categories.firstWhere(
      (c) => c['name'] == item.category,
      orElse: () => AppConstants.categories.last,
    );
    final icon = catData['icon'] as IconData;
    final color = catData['color'] as Color;

    return InteractiveCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16.0),
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.complaintDetail,
          arguments: item,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.complaintId,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              StatusBadge(status: item.status, isCompact: true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.lightTextMuted),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      item.location,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                DateFormatter.formatRelative(item.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.lightTextMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
