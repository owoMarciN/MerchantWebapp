import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/global/global.dart';
import 'package:user_app/widgets/progress_bar.dart';
import 'package:go_router/go_router.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final String? _restaurantID = currentUid;

  Map<String, dynamic>? _restaurantData;
  Map<String, dynamic>? _userData;
  bool _hasMenus = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection("restaurants").doc(_restaurantID).get(),
        FirebaseFirestore.instance.collection("users").doc(_restaurantID).get(),
        _checkHasMenusAndItems(),
      ]);

      if (!mounted) return;
      setState(() {
        _restaurantData = (results[0] as DocumentSnapshot).data() as Map<String, dynamic>?;
        _userData = (results[1] as DocumentSnapshot).data() as Map<String, dynamic>?;
        _hasMenus = results[2] as bool;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkHasMenusAndItems() async {
    if (_restaurantID == null) return false;
    final menus = await FirebaseFirestore.instance
        .collection("restaurants")
        .doc(_restaurantID)
        .collection("menus")
        .limit(1)
        .get();
    if (menus.docs.isEmpty) return false;
    final items = await FirebaseFirestore.instance
        .collection("restaurants")
        .doc(_restaurantID)
        .collection("menus")
        .doc(menus.docs.first.id)
        .collection("items")
        .limit(1)
        .get();
    return items.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(child: circularProgress());
    }

    final bool hasLogo = (_restaurantData?["logoUrl"] ?? "").toString().isNotEmpty;
    final bool hasBanner = (_restaurantData?["bannerUrl"] ?? "").toString().isNotEmpty;
    final bool hasAddress = (_restaurantData?["address"] ?? "").toString().isNotEmpty;
    final bool hasStripe = _restaurantData?["stripeConnected"] == true;
    final bool hasProfilePhoto = (_userData?["photoUrl"] ?? "").toString().isNotEmpty;

    final List<_SetupTask> tasks = [
      _SetupTask(icon: Icons.add_a_photo_rounded, title: 'Upload Restaurant Logo', description: 'Customers will see your logo across the app.', done: hasLogo, route: '/dashboard/settings'),
      _SetupTask(icon: Icons.panorama_rounded, title: 'Add a Banner Image', description: 'A banner makes your storefront visually appealing.', done: hasBanner, route: '/dashboard/settings'),
      _SetupTask(icon: Icons.location_on_rounded, title: 'Set Restaurant Address', description: 'Let customers know where to find you.', done: hasAddress, route: '/dashboard/settings'),
      _SetupTask(icon: Icons.person_rounded, title: 'Add a Profile Photo', description: 'Put a face to your restaurant owner account.', done: hasProfilePhoto, route: '/dashboard/settings'),
      _SetupTask(icon: Icons.restaurant_menu_rounded, title: 'Create a Menu & Add Items', description: 'Organise your offerings into menus with dishes and prices.', done: _hasMenus, route: '/dashboard/menus'),
      _SetupTask(icon: Icons.credit_card_rounded, title: 'Connect Stripe Payments', description: 'Accept online payments from customers via Stripe.', done: hasStripe, route: '/dashboard/settings'),
    ];

    final int completedCount = tasks.where((t) => t.done).length;
    final double progress = completedCount / tasks.length;
    final bool allDone = completedCount == tasks.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${getUserPref<String>("name") ?? "Chef"} 👋',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            "Here's what's happening with your restaurant today.",
            style: TextStyle(fontSize: 14, color: brandColors.muted),
          ),
          const SizedBox(height: 28),

          if (!allDone) ...[
            _buildSetupCard(context, tasks, completedCount, progress, brandColors, colorScheme),
            const SizedBox(height: 32),
          ],

          _sectionLabel('AT A GLANCE', brandColors),
          const SizedBox(height: 14),
          _buildStatGrid(brandColors, colorScheme),
          const SizedBox(height: 32),

          _sectionLabel('RECENT ORDERS', brandColors),
          const SizedBox(height: 14),
          _buildOrdersTable(brandColors, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSetupCard(
    BuildContext context,
    List<_SetupTask> tasks,
    int completedCount,
    double progress,
    BrandColors brandColors,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: brandColors.navy?.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.rocket_launch_rounded, size: 20, color: brandColors.navy),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Get your restaurant ready', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('$completedCount of ${tasks.length} steps completed', style: TextStyle(fontSize: 12, color: brandColors.muted)),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: brandColors.navy),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.outline,
              valueColor: AlwaysStoppedAnimation<Color>(brandColors.navy!),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 20),
          ...tasks.asMap().entries.map((entry) =>
              _buildTaskRow(context, entry.value, entry.key, tasks.length, brandColors, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildTaskRow(
    BuildContext context,
    _SetupTask task,
    int index,
    int total,
    BrandColors brandColors,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: task.done ? null : () => Router.neglect(context, () => context.go(task.route)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: task.done
                        ? brandColors.accentGreen?.withValues(alpha: 0.12)
                        : brandColors.navy?.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: task.done
                          ? brandColors.accentGreen?.withValues(alpha: 0.4) ?? colorScheme.outline
                          : colorScheme.outline,
                    ),
                  ),
                  child: Icon(
                    task.done ? Icons.check_rounded : task.icon,
                    size: 18,
                    color: task.done ? brandColors.accentGreen : brandColors.navy,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: task.done ? brandColors.muted : null,
                          decoration: task.done ? TextDecoration.lineThrough : null,
                          decorationColor: brandColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(task.description, style: TextStyle(fontSize: 12, color: brandColors.muted, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                task.done
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: brandColors.accentGreen?.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: brandColors.accentGreen)),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: brandColors.navy?.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Set up', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: brandColors.navy)),
                      ),
              ],
            ),
          ),
        ),
        if (index < total - 1)
          Divider(height: 1, color: colorScheme.outline, indent: 50),
      ],
    );
  }

  Widget _sectionLabel(String text, BrandColors brandColors) {
    return Text(
      text,
      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: brandColors.muted, letterSpacing: 1.2),
    );
  }

  Widget _buildStatGrid(BrandColors brandColors, ColorScheme colorScheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("orders")
          .where("restaurantID", isEqualTo: _restaurantID)
          .snapshots(),
      builder: (context, snap) {
        final int totalOrders = snap.data?.docs.length ?? 0;
        final int pendingOrders = snap.data?.docs.where((d) => (d.data() as Map)["status"] == "Pending").length ?? 0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final int cols = constraints.maxWidth > 500 ? 4 : 2;
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 96,
              ),
              children: [
                _StatCard(label: 'Total Orders', value: '$totalOrders', icon: Icons.shopping_bag_rounded, color: brandColors.navy!, colorScheme: colorScheme),
                _StatCard(label: 'Pending', value: '$pendingOrders', icon: Icons.pending_actions_rounded, color: const Color(0xFFD97706), colorScheme: colorScheme),
                _StatCard(label: 'Total Revenue', value: '—', icon: Icons.payments_rounded, color: brandColors.accentGreen!, colorScheme: colorScheme),
                _StatCard(label: 'Avg Rating', value: '—', icon: Icons.star_rounded, color: const Color(0xFFEF4444), colorScheme: colorScheme),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersTable(BrandColors brandColors, ColorScheme colorScheme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("orders")
          .where("restaurantID", isEqualTo: _restaurantID)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.hasError || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Center(
              child: Text('No orders yet', style: TextStyle(fontSize: 13, color: brandColors.muted)),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: const [
                    Expanded(flex: 3, child: _TableHeader('ORDER ID')),
                    Expanded(flex: 3, child: _TableHeader('CUSTOMER')),
                    Expanded(flex: 2, child: _TableHeader('ITEMS')),
                    Expanded(flex: 3, child: _TableHeader('STATUS')),
                    Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: _TableHeader('TOTAL'))),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outline),
              ...snapshot.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final String status = d["status"] ?? "Pending";
                final String customer = d["customerName"] ?? "—";
                final int items = (d["itemIDs"] as List?)?.length ?? 0;
                final double total = (d["totalAmount"] ?? 0).toDouble();
                final String shortId = '#${doc.id.substring(0, doc.id.length.clamp(0, 8))}';
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(shortId, style: TextStyle(fontSize: 12, color: brandColors.muted, fontFamily: 'monospace'))),
                          Expanded(flex: 3, child: Text(customer, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                          Expanded(flex: 2, child: Text('$items item${items == 1 ? '' : 's'}', style: TextStyle(fontSize: 13, color: brandColors.muted))),
                          Expanded(flex: 3, child: _StatusChip(status: status, brandColors: brandColors)),
                          Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('${total.toStringAsFixed(2)} PLN', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: colorScheme.outline),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────────

class _SetupTask {
  final IconData icon;
  final String title;
  final String description;
  final bool done;
  final String route;
  const _SetupTask({required this.icon, required this.title, required this.description, required this.done, required this.route});
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final ColorScheme colorScheme;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Flexible(child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11, color: brandColors.muted)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final BrandColors brandColors;
  const _StatusChip({required this.status, required this.brandColors});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'Pending' => (const Color(0xFFFEF3C7).withValues(alpha: 0.5), const Color(0xFFD97706)),
      'In Progress' => (brandColors.navy!.withValues(alpha: 0.15), brandColors.navy!),
      'Ready' => (brandColors.accentGreen!.withValues(alpha: 0.15), brandColors.accentGreen!),
      'Delivered' => (brandColors.muted!.withValues(alpha: 0.1), brandColors.muted!),
      _ => (brandColors.muted!.withValues(alpha: 0.1), brandColors.muted!),
    };
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF8A8AA8), letterSpacing: 0.8));
  }
}