import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/extensions/responsive_ext.dart';
import 'package:user_app/providers/global_stats_provider.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final stats = context.watch<GlobalStatsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('PLATFORM AT A GLANCE', brand),
          const SizedBox(height: 14),
          _buildStatGrid(context, brand, scheme, stats),
          const SizedBox(height: 32),
          _sectionLabel('REVENUE (LAST 30 DAYS)', brand),
          const SizedBox(height: 14),
          _RevenueChart(
              data: stats.revenueForRange(30),
              brand: brand,
              scheme: scheme),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                  child: _sectionLabel('PENDING JOIN REQUESTS', brand)),
              TextButton.icon(
                onPressed: () =>
                    Router.neglect(context, () => context.go('/admin/join-requests')),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('View all',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PendingRequestsList(brand: brand, scheme: scheme),
          const SizedBox(height: 32),
          _sectionLabel('ORDER STATUS BREAKDOWN', brand),
          const SizedBox(height: 14),
          _StatusBreakdown(
              counts: stats.statusCounts,
              total: stats.totalOrders,
              brand: brand,
              scheme: scheme),
          const SizedBox(height: 32),
          _sectionLabel('TOP RESTAURANTS BY ORDERS', brand),
          const SizedBox(height: 14),
          _TopRestaurants(
              entries: stats.topRestaurantsByOrders(limit: 5),
              brand: brand,
              scheme: scheme),
        ],
      ),
    );
  }

  // ── Stat grid ─────────────────────────────────────────────────────────────

  Widget _buildStatGrid(BuildContext context, BrandColors brand,
      ColorScheme scheme, GlobalStatsProvider stats) {
    final isWide = context.isWide;
    final cols = isWide ? 4 : 2;

    final cards = [
      _StatCard(
        label: 'Total Restaurants',
        value: stats.isLoading ? '—' : '${stats.totalRestaurants}',
        sub: '${stats.activeRestaurants} with orders',
        icon: Icons.storefront_rounded,
        color: brand.navy!,
        scheme: scheme,
      ),
      _StatCard(
        label: 'Total Orders',
        value: stats.isLoading ? '—' : '${stats.totalOrders}',
        sub: '${stats.todayOrders} today',
        icon: Icons.receipt_long_rounded,
        color: brand.accentGreen!,
        scheme: scheme,
      ),
      _StatCard(
        label: 'Total Revenue',
        value: stats.isLoading
            ? '—'
            : '${stats.totalRevenue.toStringAsFixed(0)} PLN',
        sub: '${stats.last7dRevenue.toStringAsFixed(0)} PLN last 7d',
        icon: Icons.payments_rounded,
        color: const Color(0xFF8B5CF6),
        scheme: scheme,
      ),
      _StatCard(
        label: 'Avg Order Value',
        value: stats.isLoading
            ? '—'
            : '${stats.avgOrderValue.toStringAsFixed(2)} PLN',
        sub: '${stats.totalMenus} menus · ${stats.totalItems} items',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFFD97706),
        scheme: scheme,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 100,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => cards[i],
    );
  }

  Widget _sectionLabel(String text, BrandColors brand) => Text(
        text,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: brand.muted,
            letterSpacing: 1.2),
      );
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  final ColorScheme scheme;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(fontSize: 11, color: brand.muted)),
          Text(sub,
              style: TextStyle(
                  fontSize: 10,
                  color: brand.muted?.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

// ── Revenue chart ─────────────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  final Map<String, double> data;
  final BrandColors brand;
  final ColorScheme scheme;

  const _RevenueChart(
      {required this.data, required this.brand, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxValue = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxValue == 0 ? 1.0 : maxValue;
    final int labelStep = entries.length > 14 ? 5 : 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.asMap().entries.map((entry) {
                final double value = entry.value.value;
                final double ratio = value / effectiveMax;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Tooltip(
                      message:
                          '${entry.value.key}: ${value.toStringAsFixed(2)} PLN',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            height: (ratio * 120).clamp(2.0, 120.0),
                            decoration: BoxDecoration(
                              color: value > 0
                                  ? const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.8)
                                  : scheme.outline,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: entries.asMap().entries.map((entry) {
              final bool show = entry.key % labelStep == 0;
              return Expanded(
                child: Text(
                  show ? entry.value.key : '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: brand.muted),
                ),
              );
            }).toList(),
          ),
          if (maxValue == 0) ...[
            const SizedBox(height: 8),
            Text('No revenue data yet',
                style: TextStyle(fontSize: 12, color: brand.muted)),
          ],
        ],
      ),
    );
  }
}

// ── Pending requests list ─────────────────────────────────────────────────────
// Shows up to 3 most recent pending requests inline on the overview.
// Full list is on the JoinRequestsScreen.

class _PendingRequestsList extends StatelessWidget {
  final BrandColors brand;
  final ColorScheme scheme;

  const _PendingRequestsList(
      {required this.brand, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline),
            ),
            child: Center(
              child: Text('No pending requests',
                  style: TextStyle(fontSize: 13, color: brand.muted)),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final String name = d['name']?.toString() ?? 'Unknown';
            final String nip = d['nip']?.toString() ?? '—';
            final Timestamp? ts = d['createdAt'] as Timestamp?;
            final String date = ts != null
                ? _formatDate(ts.toDate())
                : '—';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFD97706).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.hourglass_top_rounded,
                        size: 18, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        Text('NIP: $nip · Submitted $date',
                            style: TextStyle(
                                fontSize: 11, color: brand.muted)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Router.neglect(context,
                        () => context.go('/admin/join-requests')),
                    child: const Text('Review',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ── Status breakdown ──────────────────────────────────────────────────────────

class _StatusBreakdown extends StatelessWidget {
  final Map<String, int> counts;
  final int total;
  final BrandColors brand;
  final ColorScheme scheme;

  const _StatusBreakdown({
    required this.counts,
    required this.total,
    required this.brand,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline),
        ),
        child: Center(
          child: Text('No orders yet',
              style: TextStyle(fontSize: 13, color: brand.muted)),
        ),
      );
    }

    final statuses = [
      ('normal', 'Pending', brand.navy!),
      ('processing', 'Processing', const Color(0xFF8B5CF6)),
      ('delivered', 'Delivered', brand.accentGreen!),
      ('cancelled', 'Cancelled', const Color(0xFFEF4444)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: statuses.map((s) {
          final int count = counts[s.$1] ?? 0;
          if (count == 0) return const SizedBox.shrink();
          final double pct = count / total;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: s.$3,
                          borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.$2,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                    Text('$count',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('(${(pct * 100).toInt()}%)',
                        style: TextStyle(
                            fontSize: 12, color: brand.muted)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: scheme.outline,
                    valueColor: AlwaysStoppedAnimation<Color>(s.$3),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Top restaurants ───────────────────────────────────────────────────────────

class _TopRestaurants extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  final BrandColors brand;
  final ColorScheme scheme;

  const _TopRestaurants({
    required this.entries,
    required this.brand,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline),
        ),
        child: Center(
          child: Text('No order data yet',
              style: TextStyle(fontSize: 13, color: brand.muted)),
        ),
      );
    }

    final int maxCount = entries.first.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: entries.asMap().entries.map((entry) {
          final int rank = entry.key + 1;
          final String restaurantId = entry.value.key;
          final int count = entry.value.value;
          final double pct = maxCount > 0 ? count / maxCount : 0;

          return Padding(
            padding: EdgeInsets.only(
                bottom: entry.key == entries.length - 1 ? 0 : 20),
            child: Row(
              children: [
                // Rank
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: rank <= 3
                        ? brand.navy?.withValues(alpha: 0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('$rank',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: rank <= 3 ? brand.navy : brand.muted)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fetch restaurant name from Firestore
                      _RestaurantName(
                          restaurantId: restaurantId, brand: brand),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: scheme.outline,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              brand.navy ?? scheme.primary),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('$count orders',
                    style:
                        TextStyle(fontSize: 12, color: brand.muted)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Fetches the restaurant name for display in top restaurants list
class _RestaurantName extends StatelessWidget {
  final String restaurantId;
  final BrandColors brand;

  const _RestaurantName(
      {required this.restaurantId, required this.brand});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final String name =
            data?['name']?.toString() ?? restaurantId;
        return Text(name,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis);
      },
    );
  }
}