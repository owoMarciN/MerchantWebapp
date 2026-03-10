import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/extensions/extensions_import.dart';

import 'package:go_router/go_router.dart';
import 'package:user_app/global/global.dart';
import 'package:user_app/widgets/language_button.dart';
import 'package:user_app/widgets/notification_bell.dart';

class DashboardShell extends StatefulWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  List<_NavItem> _navItems(BuildContext context) => [
    _NavItem(icon: Icons.grid_view_rounded,       label: context.l10n.shell_nav_overview,    path: '/dashboard'),
    _NavItem(icon: Icons.receipt_long_rounded,    label: context.l10n.shell_nav_orders,      path: '/dashboard/orders'),
    _NavItem(icon: Icons.restaurant_menu_rounded, label: context.l10n.shell_nav_menus,       path: '/dashboard/menus'),
    _NavItem(icon: Icons.campaign_rounded,        label: context.l10n.shell_nav_promotions,  path: '/dashboard/promotions'),
    _NavItem(icon: Icons.bar_chart_rounded,       label: context.l10n.shell_nav_analytics,   path: '/dashboard/analytics'),
    _NavItem(icon: Icons.settings_rounded,        label: context.l10n.shell_nav_settings,    path: '/dashboard/settings'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _navItems(context).indexWhere((e) => e.path == location);
    return index == -1 ? 0 : index;
  }

  void _onNavTap(BuildContext context, int index) {
    Router.neglect(context, () => context.go(_navItems(context)[index].path));
  }

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;
    final bool isWide = context.isWide;
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
            .collection('restaurants')
            .doc(restaurantID)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return Scaffold(
              body: Center(
                child: Text(
                  context.l10n.shell_restaurant_not_found,
                  style: TextStyle(color: brandColors.muted),
                ),
              ),
            );
          }

          final String status = data['status']?.toString() ?? 'pending';
          if (status != 'approved' && status != 'active') {
            return Scaffold(
              body: _StatusGate(status: status, brandColors: brandColors),
            );
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(restaurantID)
                .snapshots(),
            builder: (context, userSnap) {
              final userData = userSnap.data?.data() as Map<String, dynamic>?;

              final bool setupComplete =
                  (data['logoUrl'] ?? '').toString().isNotEmpty &&
                      (data['bannerUrl'] ?? '').toString().isNotEmpty &&
                      (data['address'] ?? '').toString().isNotEmpty &&
                      (userData?['photoUrl'] ?? '').toString().isNotEmpty &&
                      (data['iban'] ?? '').toString().trim().isNotEmpty;

              final String? logoUrl =
                  (data['logoUrl'] as String?)?.isNotEmpty == true
                      ? data['logoUrl'] as String
                      : null;

              final String? photoUrl =
                  (userData?['photoUrl'] as String?)?.isNotEmpty == true
                      ? userData!['photoUrl'] as String
                      : getUserPref<String>('photoUrl');

              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: Row(
                  children: [
                    if (isWide)
                      _buildSidebar(
                        context,
                        selected,
                        brandColors,
                        colorScheme,
                        setupComplete,
                        logoUrl,
                        photoUrl,
                        status,
                        restaurantID ?? '',
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          _buildTopBar(
                            restaurantID ?? '',
                            context,
                            isWide,
                            brandColors,
                            colorScheme,
                            photoUrl,
                            selected,
                          ),
                          Expanded(child: widget.child),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: isWide
                    ? null
                    : _buildBottomNav(
                        context, selected, brandColors, colorScheme),
              );
            },
          );
        },
      ),
    );
  }

  // -- Sidebar ----------------------------------------------------------------

  Widget _buildSidebar(
    BuildContext context,
    int selected,
    BrandColors brandColors,
    ColorScheme colorScheme,
    bool setupComplete,
    String? logoUrl,
    String? photoUrl,
    String status,
    String restaurantID,
  ) {
    return Container(
      width: 220,
      color: colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => Router.neglect(context, () => context.go('/')),
              child: Row(
                children: [
                  logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            logoUrl,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: brandColors.navy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.restaurant_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      getUserPref<String>('businessName') ?? 'RestaurantOS',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (!setupComplete) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () =>
                    Router.neglect(context, () => context.go('/dashboard')),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: brandColors.navy?.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: brandColors.navy?.withValues(alpha: 0.2) ??
                          Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.rocket_launch_rounded,
                          size: 14, color: brandColors.navy),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.shell_finish_setup,
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
            const SizedBox(height: 8),
          ],

          if (setupComplete) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _GoLiveButton(
                status: status,
                restaurantID: restaurantID,
                brandColors: brandColors,
              ),
            ),
            const SizedBox(height: 8),
          ],

          ...List.generate(
            _navItems(context).length,
            (i) => _buildNavTile(context, i, selected, brandColors),
          ),

          const Spacer(),
          Divider(color: colorScheme.outline, indent: 20, endIndent: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: brandColors.navy?.withValues(alpha: 0.1),
                  backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Icon(Icons.person_rounded,
                          size: 24, color: brandColors.navy)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    getUserPref<String>('accountName') ?? context.l10n.shell_my_account,
                    style: TextStyle(fontSize: 13, color: brandColors.muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
    final item = _navItems(context)[index];
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

  // -- Top bar ----------------------------------------------------------------

  Widget _buildTopBar(
    String restaurantID,
    BuildContext context,
    bool isWide,
    BrandColors brandColors,
    ColorScheme colorScheme,
    String? photoUrl,
    int selected,
  ) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outline)),
      ),
      child: Row(
        children: [
          if (!isWide) ...[
            Icon(Icons.restaurant_rounded, color: brandColors.navy, size: 22),
            const SizedBox(width: 8),
            Text(
              getUserPref<String>('businessName') ?? 'RestaurantOS',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
          if (isWide)
            Text(
              _navItems(context)[selected].label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

          const Spacer(),

          LanguageButton(brandColors: brandColors, colorScheme: colorScheme),
          const SizedBox(width: 16,),

          NotificationBell(
            uid: restaurantID,
            brandColors: brandColors,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 16),

          PopupMenuButton(
            offset: const Offset(0, 50),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: brandColors.accentGreen!,
                width: 1.2,
              ),
            ),
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
                        backgroundColor:
                            brandColors.navy?.withValues(alpha: 0.1) ??
                                Colors.grey.shade200,
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? Icon(Icons.restaurant_rounded,
                                size: 32, color: brandColors.navy)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        getUserPref<String>('businessName') ?? 'Restaurant',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        getUserPref<String>('accountEmail') ??
                            'account@email.com',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () {},
                child: Row(children: [
                  const Icon(Icons.headset_mic_outlined, size: 16),
                  const SizedBox(width: 12),
                  Text(context.l10n.shell_menu_support, style: const TextStyle(fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                onTap: () {},
                child: Row(children: [
                  const Icon(Icons.storefront_outlined, size: 16),
                  const SizedBox(width: 12),
                  Text(context.l10n.shell_menu_sales, style: const TextStyle(fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                onTap: () {},
                child: Row(children: [
                  const Icon(Icons.cookie_outlined, size: 16),
                  const SizedBox(width: 12),
                  Text(context.l10n.shell_menu_cookies, style: const TextStyle(fontSize: 13)),
                ]),
              ),
              PopupMenuItem(
                onTap: () => Router.neglect(
                    context, () => context.go('/dashboard/settings')),
                child: Row(children: [
                  const Icon(Icons.settings_outlined, size: 16),
                  const SizedBox(width: 12),
                  Text(context.l10n.shell_menu_settings, style: const TextStyle(fontSize: 13)),
                ]),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                onTap: () async {
                  await firebaseAuth.signOut();
                  if (!context.mounted) return;
                  Router.neglect(context, () => context.go('/auth/login'));
                },
                child: Row(children: [
                  const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Text(
                    context.l10n.shell_menu_logout,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
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
                  ? Icon(Icons.person_rounded,
                      size: 16, color: brandColors.accentGreen)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // -- Bottom nav -------------------------------------------------------------

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
      destinations: _navItems(context)
          .map((e) => NavigationDestination(
                icon: Icon(e.icon, color: brandColors.muted),
                selectedIcon: Icon(e.icon, color: brandColors.navy),
                label: e.label,
              ))
          .toList(),
    );
  }
}

// -- Shared widgets -----------------------------------------------------------

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}

// -- Go Live button -----------------------------------------------------------

class _GoLiveButton extends StatefulWidget {
  final String status;
  final String restaurantID;
  final BrandColors brandColors;

  const _GoLiveButton({
    required this.status,
    required this.restaurantID,
    required this.brandColors,
  });

  @override
  State<_GoLiveButton> createState() => _GoLiveButtonState();
}

class _GoLiveButtonState extends State<_GoLiveButton> {
  bool _loading = false;

  Future<void> _requestGoLive() async {
    setState(() => _loading = true);
    try {
      final db = FirebaseFirestore.instance;

      final existing =
          await db.collection('goLiveRequests').doc(widget.restaurantID).get();

      if (existing.exists &&
          existing.data()?['status']?.toString() == 'pending') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.shell_already_pending)),
        );
        return;
      }

      await db.collection('goLiveRequests').doc(widget.restaurantID).set({
        'restaurantID': widget.restaurantID,
        'name': getUserPref<String>('businessName') ?? '',
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.shell_go_live_submitted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.shell_error(e.toString()))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goOffline() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.l10n.shell_go_offline_title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          context.l10n.shell_go_offline_body,
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.shell_confirm_cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(context.l10n.shell_go_offline_confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantID)
          .update({'status': 'approved'});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.shell_error(e.toString()))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.brandColors;

    if (_loading) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: brand.navy?.withValues(alpha: 0.2) ?? Colors.transparent),
        ),
        child: const Center(
          child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    // Active → Go Offline
    if (widget.status == 'active') {
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _goOffline,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: brand.accentGreen?.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: brand.accentGreen?.withValues(alpha: 0.3) ??
                    Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: brand.accentGreen, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.shell_live_go_offline,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: brand.accentGreen),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Approved → check Go Live request state
    if (widget.status == 'approved') {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('goLiveRequests')
            .doc(widget.restaurantID)
            .snapshots(),
        builder: (context, snap) {
          final reqStatus =
              (snap.data?.data() as Map<String, dynamic>?)?['status']
                  ?.toString();

          // Pending review
          if (reqStatus == 'pending') {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFD97706).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.shell_go_live_pending,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97706)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }

          // Declined
          if (reqStatus == 'declined') {
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _requestGoLive,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded,
                        size: 14, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.shell_go_live_declined,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Default — request to go live
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _requestGoLive,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: brand.navy?.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: brand.navy?.withValues(alpha: 0.2) ??
                        Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(Icons.rocket_launch_rounded,
                      size: 14, color: brand.navy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.shell_request_go_live,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: brand.navy),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

// -- Status gate --------------------------------------------------------------

class _StatusGate extends StatelessWidget {
  final String status;
  final BrandColors brandColors;

  const _StatusGate({required this.status, required this.brandColors});

  @override
  Widget build(BuildContext context) {
    final configs = <String, _GateConfig>{
      'pending': _GateConfig(
        icon: Icons.hourglass_top_rounded,
        color: const Color(0xFFD97706),
        title: context.l10n.gate_pending_title,
        message: context.l10n.gate_pending_message,
      ),
      'rejected': _GateConfig(
        icon: Icons.cancel_rounded,
        color: const Color(0xFFEF4444),
        title: context.l10n.gate_rejected_title,
        message: context.l10n.gate_rejected_message,
      ),
      'suspended': _GateConfig(
        icon: Icons.block_rounded,
        color: const Color(0xFFEF4444),
        title: context.l10n.gate_suspended_title,
        message: context.l10n.gate_suspended_message,
      ),
    };

    final config = configs[status] ??
        _GateConfig(
          icon: Icons.info_outline_rounded,
          color: brandColors.muted ?? Colors.grey,
          title: context.l10n.gate_default_title,
          message: context.l10n.gate_default_message,
        );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: config.color, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                config.title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                config.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: brandColors.muted, height: 1.6),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () async {
                  await firebaseAuth.signOut();
                  if (!context.mounted) return;
                  Router.neglect(context, () => context.go('/auth/login'));
                },
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: Text(context.l10n.gate_sign_out),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateConfig {
  final IconData icon;
  final Color color;
  final String title, message;
  const _GateConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}