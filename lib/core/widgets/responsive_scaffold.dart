import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../motion/app_motion.dart';
import 'campusfix_brand_logo.dart';

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget? badge;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.badge,
  });
}

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final List<NavigationItem> items;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showAppBar;
  final Widget? customHeader;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.items,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showAppBar = true,
    this.customHeader,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;
    final isTablet = width >= 720 && width < 1024;
    final isReduced = AppMotion.isReducedMotion(context);

    final animatedBody = isReduced
        ? body
        : AnimatedSwitcher(
            duration: AppMotion.durationNormal,
            switchInCurve: AppMotion.curveDecelerate,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(currentIndex),
              child: body,
            ),
          );

    // Desktop & Tablet Layout with Premium Branded Sidebar
    if (isDesktop || isTablet) {
      final sidebarWidth = isDesktop ? 275.0 : 255.0;

      return Scaffold(
        backgroundColor: AppColors.lightBackground,
        body: Row(
          children: [
            // Deep Navy Premium Sidebar
            SizedBox(
              width: sidebarWidth,
              child: _SidebarContent(
                currentIndex: currentIndex,
                onNavigationChanged: onNavigationChanged,
                items: items,
              ),
            ),

            // Main Content Area with Header
            Expanded(
              child: Scaffold(
                backgroundColor: AppColors.lightBackground,
                appBar: showAppBar
                    ? AppBar(
                        elevation: 0,
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        title: customHeader ??
                            Row(
                              children: [
                                const Text(
                                  'CampusFix',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '/',
                                  style: TextStyle(fontSize: 14, color: AppColors.lightTextMuted),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.lightTextPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                        actions: actions,
                        bottom: const PreferredSize(
                          preferredSize: Size.fromHeight(1),
                          child: Divider(height: 1, color: AppColors.lightBorder),
                        ),
                      )
                    : null,
                body: animatedBody,
                floatingActionButton: floatingActionButton,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile Layout with Branded Drawer + Bottom Navigation
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: showAppBar
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: customHeader ??
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: AppColors.primaryGradient,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'CF',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
              actions: actions,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: AppColors.lightBorder),
              ),
            )
          : null,
      drawer: Drawer(
        child: _SidebarContent(
          currentIndex: currentIndex,
          onNavigationChanged: (index) {
            Navigator.pop(context); // close drawer on mobile
            onNavigationChanged(index);
          },
          items: items,
        ),
      ),
      body: animatedBody,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onNavigationChanged,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: AppColors.lightTextSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          items: items.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1.0),
                duration: AppMotion.durationFast,
                curve: AppMotion.curveSpring,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: Icon(item.selectedIcon, color: AppColors.secondary),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Premium Modern Sidebar Widget for CampusFix + LBRCE
class _SidebarContent extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final List<NavigationItem> items;

  const _SidebarContent({
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.items,
  });

  @override
  State<_SidebarContent> createState() => _SidebarContentState();
}

class _SidebarContentState extends State<_SidebarContent> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF062B55), // Deep Navy #062B55
            Color(0xFF041E3D), // Dark Navy
            Color(0xFF03162C),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: Color(0xFF0F325E),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top LBRCE + CampusFix Branding
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 20, 18, 16),
              child: CampusFixBrandLogo(
                logoSize: 40,
                isDark: true,
                showCollegeDetails: true,
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Divider(color: Color(0xFF0F3666), height: 1),
            ),
            const SizedBox(height: 16),

            // Navigation Items List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: widget.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final isActive = widget.currentIndex == index;
                  final isHovered = _hoveredIndex == index;

                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredIndex = index),
                    onExit: (_) => setState(() => _hoveredIndex = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: isActive
                            ? AppColors.activeNavGradient
                            : (isHovered
                                ? LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.08),
                                      Colors.white.withValues(alpha: 0.04),
                                    ],
                                  )
                                : null),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppColors.brightBlue.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => widget.onNavigationChanged(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  isActive ? item.selectedIcon : item.icon,
                                  size: 20,
                                  color: isActive
                                      ? Colors.white
                                      : (isHovered ? const Color(0xFFE2E8F0) : const Color(0xFF94A3B8)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                      color: isActive
                                          ? Colors.white
                                          : (isHovered ? const Color(0xFFE2E8F0) : const Color(0xFF94A3B8)),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                if (isActive)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentCyan,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Information Area: TOGETHER FOR A BETTER CAMPUS
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: AppColors.accentCyan,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'TOGETHER FOR A\nBETTER CAMPUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: Color(0xFFE2E8F0),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const _SidebarFeatureItem(text: 'Report Problems', icon: Icons.report_problem_outlined),
                    const SizedBox(height: 5),
                    const _SidebarFeatureItem(text: 'Track Progress', icon: Icons.trending_up_rounded),
                    const SizedBox(height: 5),
                    const _SidebarFeatureItem(text: 'Build Community', icon: Icons.groups_outlined),
                    const SizedBox(height: 5),
                    const _SidebarFeatureItem(text: 'Keep Campus Clean', icon: Icons.eco_outlined),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarFeatureItem extends StatelessWidget {
  final String text;
  final IconData icon;

  const _SidebarFeatureItem({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: AppColors.accentCyan,
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
