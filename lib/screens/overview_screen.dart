import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/extensions/extensions_import.dart';
import 'package:user_app/global/global.dart';
import 'package:user_app/widgets/progress_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:user_app/providers/local_stats_provider.dart';

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
        FirebaseFirestore.instance
            .collection("restaurants")
            .doc(_restaurantID)
            .get(),
        FirebaseFirestore.instance.collection("users").doc(_restaurantID).get(),
        _checkHasMenusAndItems(),
      ]);

      if (!mounted) return;
      setState(() {
        _restaurantData =
            (results[0] as DocumentSnapshot).data() as Map<String, dynamic>?;
        _userData =
            (results[1] as DocumentSnapshot).data() as Map<String, dynamic>?;
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

    final bool hasLogo =
        (_restaurantData?["logoUrl"] ?? "").toString().isNotEmpty;
    final bool hasBanner =
        (_restaurantData?["bannerUrl"] ?? "").toString().isNotEmpty;
    final bool hasAddress =
        (_restaurantData?["address"] ?? "").toString().isNotEmpty;
    final bool hasProfilePhoto =
        (_userData?["photoUrl"] ?? "").toString().isNotEmpty;
    final bool hasIban =
        (_restaurantData?["iban"] ?? "").toString().trim().isNotEmpty;

    final List<_SetupTask> tasks = [
      _SetupTask(
        icon: Icons.add_a_photo_rounded,
        title: context.l10n.overview_task_logo_title,
        description: context.l10n.overview_task_logo_desc,
        done: hasLogo,
        route: '/dashboard/settings',
      ),
      _SetupTask(
        icon: Icons.panorama_rounded,
        title: context.l10n.overview_task_banner_title,
        description: context.l10n.overview_task_banner_desc,
        done: hasBanner,
        route: '/dashboard/settings',
      ),
      _SetupTask(
        icon: Icons.location_on_rounded,
        title: context.l10n.overview_task_address_title,
        description: context.l10n.overview_task_address_desc,
        done: hasAddress,
        route: '/dashboard/settings',
      ),
      _SetupTask(
        icon: Icons.person_rounded,
        title: context.l10n.overview_task_photo_title,
        description: context.l10n.overview_task_photo_desc,
        done: hasProfilePhoto,
        route: '/dashboard/settings',
      ),
      _SetupTask(
        icon: Icons.restaurant_menu_rounded,
        title: context.l10n.overview_task_menu_title,
        description: context.l10n.overview_task_menu_desc,
        done: _hasMenus,
        route: '/dashboard/menus',
      ),
      _SetupTask(
        icon: Icons.account_balance_rounded,
        title: context.l10n.overview_task_iban_title,
        description: context.l10n.overview_task_iban_desc,
        done: hasIban,
        route: '/dashboard/settings',
      ),
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
            context.l10n.overview_welcome(
                getUserPref<String>("accountName") ?? context.l10n.overview_chef_fallback),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.overview_subtitle,
            style: TextStyle(fontSize: 14, color: brandColors.muted),
          ),
          const SizedBox(height: 28),
          if (!allDone) ...[
            _buildSetupCard(context, tasks, completedCount, progress,
                brandColors, colorScheme),
            const SizedBox(height: 32),
          ],
          _sectionLabel(context.l10n.overview_section_glance, brandColors),
          const SizedBox(height: 14),
          _buildStatGrid(brandColors, colorScheme),
          const SizedBox(height: 32),
          _sectionLabel(context.l10n.overview_section_orders, brandColors),
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
                child: Icon(Icons.rocket_launch_rounded,
                    size: 20, color: brandColors.navy),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.overview_setup_title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                        context.l10n.overview_setup_progress(
                            completedCount, tasks.length),
                        style:
                            TextStyle(fontSize: 12, color: brandColors.muted)),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: brandColors.navy),
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
          ...tasks.asMap().entries.map((entry) => _buildTaskRow(context,
              entry.value, entry.key, tasks.length, brandColors, colorScheme)),
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
          onTap: task.done
              ? null
              : () => Router.neglect(context, () => context.go(task.route)),
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
                          ? brandColors.accentGreen?.withValues(alpha: 0.4) ??
                              colorScheme.outline
                          : colorScheme.outline,
                    ),
                  ),
                  child: Icon(
                    task.done ? Icons.check_rounded : task.icon,
                    size: 18,
                    color:
                        task.done ? brandColors.accentGreen : brandColors.navy,
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
                          decoration:
                              task.done ? TextDecoration.lineThrough : null,
                          decorationColor: brandColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(task.description,
                          style: TextStyle(
                              fontSize: 12,
                              color: brandColors.muted,
                              height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                task.done
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              brandColors.accentGreen?.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(context.l10n.overview_task_done,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: brandColors.accentGreen)),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: brandColors.navy?.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(context.l10n.overview_task_setup,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: brandColors.navy)),
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
      style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: brandColors.muted,
          letterSpacing: 1.2),
    );
  }

  Widget _buildStatGrid(BrandColors brandColors, ColorScheme colorScheme) {
    final stats = context.watch<LocalStatsProvider>();
    return LayoutBuilder(builder: (context, constraints) {
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
          _StatCard(
              label: context.l10n.overview_stat_total_orders,
              value: '${stats.totalOrders}',
              icon: Icons.shopping_bag_rounded,
              color: brandColors.navy!,
              colorScheme: colorScheme),
          _StatCard(
              label: context.l10n.overview_stat_pending,
              value: '${stats.pendingOrders}',
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFFD97706),
              colorScheme: colorScheme),
          _StatCard(
              label: context.l10n.overview_stat_completed,
              value: '${stats.completedOrders}',
              icon: Icons.check_circle_rounded,
              color: brandColors.accentGreen!,
              colorScheme: colorScheme),
          _StatCard(
              label: context.l10n.overview_stat_revenue,
              value: '${stats.totalRevenue.toStringAsFixed(2)} PLN',
              icon: Icons.payments_rounded,
              color: const Color(0xFF8B5CF6),
              colorScheme: colorScheme),
        ],
      );
    });
  }

  Widget _buildOrdersTable(BrandColors brandColors, ColorScheme colorScheme) {
    final stats = context.watch<LocalStatsProvider>();
    final recentDocs = stats.docs.take(5).toList();

    if (recentDocs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline)),
        child: Center(
            child: Text(context.l10n.overview_no_orders,
                style: TextStyle(fontSize: 13, color: brandColors.muted))),
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
              children: [
                Expanded(flex: 3, child: _TableHeader(context.l10n.overview_table_order_id)),
                Expanded(flex: 3, child: _TableHeader(context.l10n.overview_table_customer)),
                Expanded(flex: 2, child: _TableHeader(context.l10n.overview_table_items)),
                Expanded(flex: 3, child: _TableHeader(context.l10n.overview_table_status)),
                Expanded(
                    flex: 2,
                    child: Align(
                        alignment: Alignment.centerRight,
                        child: _TableHeader(context.l10n.overview_table_total))),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outline),
          ...recentDocs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final String status = d["status"] ?? "normal";
            final String customer = d["userID"] ?? "—";
            final int items = (d["itemIDs"] as List?)?.length ?? 0;
            final double total =
                double.tryParse(d["totalAmount"]?.toString() ?? "0") ?? 0;
            final Timestamp? ts = d["orderTime"] as Timestamp?;
            final String timeLabel =
                ts != null ? _formatTime(context, ts.toDate()) : "—";
            final String shortId =
                '#${doc.id.substring(0, doc.id.length.clamp(0, 8))}';
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(shortId,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: brandColors.muted,
                                    fontFamily: 'monospace')),
                            const SizedBox(height: 2),
                            Text(timeLabel,
                                style: TextStyle(
                                    fontSize: 10, color: brandColors.muted)),
                          ],
                        ),
                      ),
                      Expanded(
                          flex: 3,
                          child: Text(customer,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis)),
                      Expanded(
                          flex: 2,
                          child: Text(
                              items == 1
                                  ? context.l10n.overview_items_count(items)
                                  : context.l10n.overview_items_count_plural(items),
                              style: TextStyle(
                                  fontSize: 13, color: brandColors.muted))),
                      Expanded(
                          flex: 3,
                          child: _StatusChip(
                              status: status, brandColors: brandColors)),
                      Expanded(
                          flex: 2,
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: Text('${total.toStringAsFixed(2)} PLN',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)))),
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
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return context.l10n.overview_time_just_now;
    if (diff.inMinutes < 60) return context.l10n.overview_time_minutes(diff.inMinutes);
    if (diff.inHours < 24) return context.l10n.overview_time_hours(diff.inHours);
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}';
  }
}

// --- Supporting widgets ------------------------------------------------------

class _SetupTask {
  final IconData icon;
  final String title;
  final String description;
  final bool done;
  final String route;
  const _SetupTask({
    required this.icon,
    required this.title,
    required this.description,
    required this.done,
    required this.route,
  });
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final ColorScheme colorScheme;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.colorScheme,
  });

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
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Flexible(
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis)),
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
      'normal' => (
          const Color(0xFFFEF3C7).withValues(alpha: 0.5),
          const Color(0xFFD97706)
        ),
      'processing' => (
          brandColors.navy!.withValues(alpha: 0.15),
          brandColors.navy!
        ),
      'ready' => (
          brandColors.accentGreen!.withValues(alpha: 0.15),
          brandColors.accentGreen!
        ),
      'delivered' => (
          brandColors.muted!.withValues(alpha: 0.1),
          brandColors.muted!
        ),
      'cancelled' => (
          const Color(0xFFEF4444).withValues(alpha: 0.1),
          const Color(0xFFEF4444)
        ),
      _ => (brandColors.muted!.withValues(alpha: 0.1), brandColors.muted!),
    };
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(status,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8A8AA8),
            letterSpacing: 0.8));
  }
}