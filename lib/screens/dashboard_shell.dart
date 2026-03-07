import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:user_app/extensions/responsive_ext.dart';
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
  static const List<_NavItem> _navItems = [
    _NavItem(
        icon: Icons.grid_view_rounded, label: 'Overview', path: '/dashboard'),
    _NavItem(
        icon: Icons.receipt_long_rounded,
        label: 'Orders',
        path: '/dashboard/orders'),
    _NavItem(
        icon: Icons.restaurant_menu_rounded,
        label: 'Menus',
        path: '/dashboard/menus'),
    _NavItem(
        icon: Icons.campaign_rounded,
        label: 'Promotions',
        path: '/dashboard/promotions'),
    _NavItem(
        icon: Icons.bar_chart_rounded,
        label: 'Analytics',
        path: '/dashboard/analytics'),
    _NavItem(
        icon: Icons.settings_rounded,
        label: 'Settings',
        path: '/dashboard/settings'),
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
          // -- First load only ------------------------------------------------
          // Use snap.hasData so subsequent stream events never flash a spinner.
          // ConnectionState.waiting on re-emits would destroy the shell layout.
          if (!snap.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // -- Missing document -----------------------------------------------
          final data = snap.data!.data() as Map<String, dynamic>?;
          if (data == null) {
            return Scaffold(
              body: Center(
                child: Text(
                  'Restaurant not found. Please contact support.',
                  style: TextStyle(color: brandColors.muted),
                ),
              ),
            );
          }

          // -- Status gate ----------------------------------------------------
          // Shown only when status is genuinely blocked.
          // snap.hasData means this evaluates against real Firestore data,
          // never against a transient loading state.
          final String status = data['status']?.toString() ?? 'pending';
          if (status != 'approved' && status != 'active') {
            return Scaffold(
              body: _StatusGate(status: status, brandColors: brandColors),
            );
          }

          // -- Dashboard ------------------------------------------------------
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

          // Logo + name — tapping returns to landing page
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

          // Finish setup banner
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
            const SizedBox(height: 8),
          ],

          // Go Live / Go Offline button
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

          // Nav items
          ...List.generate(
            _navItems.length,
            (i) => _buildNavTile(context, i, selected, brandColors),
          ),

          const Spacer(),
          Divider(color: colorScheme.outline, indent: 20, endIndent: 20),

          // Account row
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
                    getUserPref<String>('accountName') ?? 'My Account',
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

  // -- Top bar -------------------------------------------------------------------

  Widget _buildTopBar(
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
          // Left side
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
              _navItems[selected].label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

          const Spacer(),

          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.notifications_none, color: brandColors.muted),
          ),
          const SizedBox(width: 16),

          PopupMenuButton(
            offset: const Offset(0, 50),
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                // ← border
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
                onTap: () => Router.neglect(
                    context, () => context.go('/dashboard/settings')),
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
                  Text(
                    'Log out',
                    style: TextStyle(
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

  // -- Bottom nav -----------------------------------------------------------------------------
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

// -- Shared widgets -----------------------------------------------------------------------------

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TopBarButton(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
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

// -- Go Live button -----------------------------------------------------------------------------

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
          const SnackBar(
              content: Text('You already have a pending Go Live request.')),
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
        const SnackBar(
            content:
                Text("Go Live request submitted. We'll review it shortly.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goOffline() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Go Offline?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'Your restaurant will be hidden from customers. You can go live again at any time.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Go Offline'),
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
          .showSnackBar(SnackBar(content: Text('Error: $e')));
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
                  'Live · Go Offline',
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
                      'Go Live pending review',
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
                        'Declined · Reapply',
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
                      'Request Go Live',
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
        title: 'Your account is under review',
        message:
            "We're reviewing your registration details. This usually takes 1-2 business days. We'll notify you by email once approved.",
      ),
      'rejected': _GateConfig(
        icon: Icons.cancel_rounded,
        color: const Color(0xFFEF4444),
        title: 'Application not approved',
        message:
            'Unfortunately your registration was not approved. Please contact support for more information.',
      ),
      'suspended': _GateConfig(
        icon: Icons.block_rounded,
        color: const Color(0xFFEF4444),
        title: 'Account suspended',
        message:
            'Your account has been suspended. Please contact support to resolve this.',
      ),
    };

    final config = configs[status] ??
        _GateConfig(
          icon: Icons.info_outline_rounded,
          color: brandColors.muted ?? Colors.grey,
          title: 'Access unavailable',
          message: 'Please contact support.',
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
                label: const Text('Sign out'),
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
