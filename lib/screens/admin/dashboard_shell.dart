import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/global/global.dart';
import 'package:user_app/extensions/responsive_ext.dart';

class AdminDashboardShell extends StatelessWidget {
  final Widget child;
  const AdminDashboardShell({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(
        icon: Icons.grid_view_rounded,
        label: 'Overview',
        path: '/admin/overview'),
    _NavItem(
        icon: Icons.storefront_rounded,
        label: 'Join Requests',
        path: '/admin/join-requests'),
    _NavItem(icon: Icons.people_rounded, label: 'Users', path: '/admin/users'),
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
    final brand = Theme.of(context).extension<BrandColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final isWide = context.isWide;
    final int selected = _selectedIndex(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await firebaseAuth.signOut();
          if (!context.mounted) return;
          Router.neglect(context, () => context.go('/auth/login'));
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Row(
          children: [
            if (isWide)
              _AdminSidebar(
                navItems: _navItems,
                selected: selected,
                brand: brand,
                scheme: scheme,
                onTap: (i) => _onNavTap(context, i),
              ),
            Expanded(
              child: Column(
                children: [
                  _AdminTopBar(
                    isWide: isWide,
                    brand: brand,
                    scheme: scheme,
                    label: _navItems[selected].label,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: isWide
            ? null
            : _AdminBottomNav(
                navItems: _navItems,
                selected: selected,
                brand: brand,
                scheme: scheme,
                onTap: (i) => _onNavTap(context, i),
              ),
      ),
    );
  }
}

// -- Sidebar ------------------------------------------------------------------
class _AdminSidebar extends StatelessWidget {
  final List<_NavItem> navItems;
  final int selected;
  final BrandColors brand;
  final ColorScheme scheme;
  final ValueChanged<int> onTap;

  const _AdminSidebar({
    required this.navItems,
    required this.selected,
    required this.brand,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: scheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 28),

          // Brand mark
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Freequick',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('Admin Panel',
                          style: TextStyle(fontSize: 10, color: brand.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Nav items
          ...navItems.asMap().entries.map((e) => _NavTile(
                item: e.value,
                isSelected: selected == e.key,
                brand: brand,
                onTap: () => onTap(e.key),
              )),

          const Spacer(),
          Divider(color: scheme.outline, indent: 20, endIndent: 20),

          // Admin identity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      size: 24, color: Color(0xFFEF4444)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getUserPref<String>("accountName") ?? 'Admin',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Administrator',
                          style: TextStyle(fontSize: 12, color: brand.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// -- Nav tile -----------------------------------------------------------------
class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final BrandColors brand;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.brand,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 18,
                color: isSelected ? const Color(0xFFEF4444) : brand.muted,
              ),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFFEF4444) : brand.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -- Top bar ------------------------------------------------------------------
class _AdminTopBar extends StatelessWidget {
  final bool isWide;
  final BrandColors brand;
  final ColorScheme scheme;
  final String label;

  const _AdminTopBar({
    required this.isWide,
    required this.brand,
    required this.scheme,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: Row(
        children: [
          if (!isWide) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.shield_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Admin',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ],
          if (isWide)
            Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Spacer(),

          // Admin badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded, size: 16, color: Color(0xFFEF4444)),
                SizedBox(width: 4),
                Text('Admin',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444))),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Sign out
          PopupMenuButton(
            offset: const Offset(0, 50),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(                        // ← border
                color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            constraints: const BoxConstraints(minWidth: 200),
            itemBuilder: (_) => <PopupMenuEntry>[
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getUserPref<String>("accountName") ?? 'Admin',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      getUserPref<String>("accountEmail") ?? '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
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
                  Text('Sign out',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent)),
                ]),
              ),
            ],
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  size: 16, color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Bottom nav ---------------------------------------------------------------
class _AdminBottomNav extends StatelessWidget {
  final List<_NavItem> navItems;
  final int selected;
  final BrandColors brand;
  final ColorScheme scheme;
  final ValueChanged<int> onTap;

  const _AdminBottomNav({
    required this.navItems,
    required this.selected,
    required this.brand,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: onTap,
      backgroundColor: scheme.surface,
      indicatorColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
      destinations: navItems
          .map((e) => NavigationDestination(
                icon: Icon(e.icon, color: brand.muted),
                selectedIcon: const Icon(Icons.circle,
                    size: 18, color: Color(0xFFEF4444)),
                label: e.label,
              ))
          .toList(),
    );
  }
}

// -- Data model ---------------------------------------------------------------
class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}
