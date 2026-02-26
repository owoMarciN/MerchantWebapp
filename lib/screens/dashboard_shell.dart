import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/global/global.dart';

class DashboardShell extends StatefulWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.grid_view_rounded, label: 'Overview', path: '/dashboard'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Orders', path: '/dashboard/orders'),
    _NavItem(icon: Icons.restaurant_menu_rounded, label: 'Menus', path: '/dashboard/menus'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Analytics', path: '/dashboard/analytics'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings', path: '/dashboard/settings'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _navItems.indexWhere((e) => e.path == location);
    return index == -1 ? 0 : index;
  }

  void _onNavTap(BuildContext context, int index) {
    Router.neglect(context, () => context.go(_navItems[index].path));
  }

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final bool isWide = MediaQuery.of(context).size.width > 700;
    final int selected = _selectedIndex(context);
    final String? restaurantID = currentUid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await firebaseAuth.signOut();
          if (!context.mounted) return;
          Router.neglect(context, () => context.go('/auth/login'));
        }
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("restaurants")
            .doc(restaurantID)
            .snapshots(),
        builder: (context, snap) {
          final data = snap.data?.data() as Map<String, dynamic>?;
          final bool setupComplete =
              (data?["logoUrl"] ?? "").toString().isNotEmpty &&
              (data?["bannerUrl"] ?? "").toString().isNotEmpty &&
              data?["stripeConnected"] == true;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                if (isWide)
                  _buildSidebar(context, selected, brandColors, colorScheme, setupComplete),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(context, isWide, brandColors, colorScheme),
                      Expanded(child: widget.child),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: isWide
                ? null
                : _buildBottomNav(context, selected, brandColors, colorScheme),
          );
        },
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    int selected,
    BrandColors brandColors,
    ColorScheme colorScheme,
    bool setupComplete,
  ) {
    final String? photoUrl = getUserPref<String>("photo");

    return Container(
      width: 220,
      color: colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 28),

          // Logo / restaurant name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                photoUrl != null && photoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(photoUrl, width: 32, height: 32, fit: BoxFit.cover),
                      )
                    : Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: brandColors.navy,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 18),
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    getUserPref<String>("name") ?? 'RestaurantOS',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Setup prompt
          if (!setupComplete) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Router.neglect(context, () => context.go('/dashboard')),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: brandColors.navy?.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: brandColors.navy?.withValues(alpha: 0.2) ?? Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.rocket_launch_rounded, size: 14, color: brandColors.navy),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Finish setup',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: brandColors.navy,
                          ),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          ...List.generate(
            _navItems.length,
            (i) => _buildNavTile(context, i, selected, brandColors),
          ),

          const Spacer(),
          Divider(color: colorScheme.outline, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListTile(
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: brandColors.navy?.withValues(alpha: 0.1),
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Icon(Icons.person_rounded, size: 16, color: brandColors.navy)
                    : null,
              ),
              title: Text(
                getUserPref<String>("name") ?? 'My Account',
                style: TextStyle(fontSize: 12, color: brandColors.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildNavTile(
    BuildContext context,
    int index,
    int selected,
    BrandColors brandColors,
  ) {
    final item = _navItems[index];
    final bool isSelected = selected == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _onNavTap(context, index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? brandColors.navy?.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 18,
                color: isSelected ? brandColors.navy : brandColors.muted,
              ),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : brandColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    bool isWide,
    BrandColors brandColors,
    ColorScheme colorScheme,
  ) {
    final String? photoUrl = getUserPref<String>("photo");

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline)),
      ),
      child: Row(
        children: [
          if (!isWide) ...[
            Icon(Icons.restaurant_rounded, color: brandColors.navy, size: 22),
            const SizedBox(width: 8),
            const Text('RestaurantOS',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ],
          if (isWide)
            Text(
              _navItems[_selectedIndex(context)].label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          const Spacer(),
          _iconBtn(brandColors, colorScheme, Icons.notifications_none_rounded),
          const SizedBox(width: 8),
          PopupMenuButton(
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            constraints: const BoxConstraints(minWidth: 240),
            itemBuilder: (_) => <PopupMenuEntry>[
              PopupMenuItem(
                enabled: false,
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white,
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? Icon(Icons.restaurant_rounded, size: 32, color: brandColors.navy)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        getUserPref<String>("name") ?? 'Restaurant',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        getUserPref<String>("email") ?? 'business@email.com',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () {},
                child: const Row(children: [
                  Icon(Icons.headset_mic_outlined, size: 16),
                  SizedBox(width: 12),
                  Text('Talk to Support', style: TextStyle(fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                onTap: () {},
                child: const Row(children: [
                  Icon(Icons.storefront_outlined, size: 16),
                  SizedBox(width: 12),
                  Text('Talk to Sales', style: TextStyle(fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                onTap: () {},
                child: const Row(children: [
                  Icon(Icons.cookie_outlined, size: 16),
                  SizedBox(width: 12),
                  Text('Cookie Preferences', style: TextStyle(fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                onTap: () => Router.neglect(context, () => context.go('/dashboard/settings')),
                child: const Row(children: [
                  Icon(Icons.settings_outlined, size: 16),
                  SizedBox(width: 12),
                  Text('Settings', style: TextStyle(fontSize: 13)),
                ]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () async {
                  await firebaseAuth.signOut();
                  if (!context.mounted) return;
                  Router.neglect(context, () => context.go('/auth/login'));
                },
                child: const Row(children: [
                  Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                  SizedBox(width: 12),
                  Text('Log out',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent)),
                ]),
              ),
            ],
            child: CircleAvatar(
              radius: 16,
              backgroundColor: brandColors.navy?.withValues(alpha: 0.3),
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? Icon(Icons.person_rounded, size: 16, color: brandColors.accentGreen)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(BrandColors brandColors, ColorScheme colorScheme, IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: brandColors.muted),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    int selected,
    BrandColors brandColors,
    ColorScheme colorScheme,
  ) {
    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (i) => _onNavTap(context, i),
      backgroundColor: colorScheme.surface,
      indicatorColor: brandColors.navy?.withValues(alpha: 0.1),
      destinations: _navItems
          .map((e) => NavigationDestination(
                icon: Icon(e.icon, color: brandColors.muted),
                selectedIcon: Icon(e.icon, color: brandColors.navy),
                label: e.label,
              ))
          .toList(),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TopBarButton({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}