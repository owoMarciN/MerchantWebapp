import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/extensions/extensions_import.dart';
import 'package:user_app/global/global.dart';
import 'package:user_app/widgets/progress_bar.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final String? _restaurantID = currentUid;
  bool _isLoading = true;

  // Range toggle: 7 or 30 days
  int _rangeDays = 7;

  // Computed analytics
  double _totalRevenue = 0;
  double _todayRevenue = 0;
  int _totalOrders = 0;
  int _todayOrders = 0;
  double _avgOrderValue = 0;

  // Chart data: date label → revenue
  Map<String, double> _revenueByDay = {};

  // Status breakdown
  Map<String, int> _statusCounts = {};

  // Popular items: itemID → count
  Map<String, int> _itemCounts = {};

  // Item name cache: itemID → name
  Map<String, String> _itemNames = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (_restaurantID == null) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final rangeStart = now.subtract(Duration(days: _rangeDays));
      final todayStart = DateTime(now.year, now.month, now.day);

      final snap = await FirebaseFirestore.instance
          .collection("orders")
          .where("restaurantID", isEqualTo: _restaurantID)
          .where("orderTime", isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
          .get();

      double totalRevenue = 0;
      double todayRevenue = 0;
      int totalOrders = snap.docs.length;
      int todayOrders = 0;
      final Map<String, double> revenueByDay = {};
      final Map<String, int> statusCounts = {};
      final Map<String, int> itemCounts = {};

      // Pre-fill days so chart has no gaps
      for (int i = _rangeDays - 1; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        revenueByDay[_dayLabel(day)] = 0;
      }

      for (final doc in snap.docs) {
        final d = doc.data();

        final double amount = double.tryParse(d["totalAmount"]?.toString() ?? "0") ?? 0;
        final Timestamp? ts = d["orderTime"] as Timestamp?;
        final String status = d["status"]?.toString() ?? "normal";
        final List itemIDs = (d["itemIDs"] as List?) ?? [];

        totalRevenue += amount;

        // Today stats
        if (ts != null) {
          final orderDate = ts.toDate();
          if (orderDate.isAfter(todayStart)) {
            todayRevenue += amount;
            todayOrders++;
          }

          // Group by day for chart
          final label = _dayLabel(orderDate);
          if (revenueByDay.containsKey(label)) {
            revenueByDay[label] = (revenueByDay[label] ?? 0) + amount;
          }
        }

        // Status breakdown
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;

        // Item frequency
        for (final id in itemIDs) {
          final key = id.toString();
          itemCounts[key] = (itemCounts[key] ?? 0) + 1;
        }
      }

      // Fetch item names for top 5 most ordered items
      final topItemIds = (itemCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .map((e) => e.key)
          .toList();

      final Map<String, String> itemNames = {};
      for (final itemId in topItemIds) {
        // Items are stored under menus subcollection — search all menus
        final menusSnap = await FirebaseFirestore.instance
            .collection("restaurants")
            .doc(_restaurantID)
            .collection("menus")
            .get();

        for (final menu in menusSnap.docs) {
          final itemSnap = await FirebaseFirestore.instance
              .collection("restaurants")
              .doc(_restaurantID)
              .collection("menus")
              .doc(menu.id)
              .collection("items")
              .doc(itemId)
              .get();

          if (itemSnap.exists) {
            itemNames[itemId] = itemSnap.data()?["name"]?.toString() ?? itemId;
            break;
          }
        }

        // Fallback if not found
        itemNames.putIfAbsent(itemId, () => itemId);
      }

      if (!mounted) return;
      setState(() {
        _totalRevenue = totalRevenue;
        _todayRevenue = todayRevenue;
        _totalOrders = totalOrders;
        _todayOrders = todayOrders;
        _avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0;
        _revenueByDay = revenueByDay;
        _statusCounts = statusCounts;
        _itemCounts = itemCounts;
        _itemNames = itemNames;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _dayLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) return Center(child: circularProgress());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stat cards ──────────────────────────────────────────────
          _sectionLabel(context.l10n.analytics_section_glance, brandColors),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
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
                  label: context.l10n.analytics_stat_revenue(_rangeDays),
                  value: '${_totalRevenue.toStringAsFixed(2)} PLN',
                  icon: Icons.payments_rounded,
                  color: brandColors.accentGreen!,
                  colorScheme: colorScheme,
                ),
                _StatCard(
                  label: context.l10n.analytics_stat_orders(_rangeDays),
                  value: '$_totalOrders',
                  icon: Icons.shopping_bag_rounded,
                  color: brandColors.navy!,
                  colorScheme: colorScheme,
                ),
                _StatCard(
                  label: context.l10n.analytics_stat_today,
                  value: '${_todayRevenue.toStringAsFixed(2)} PLN',
                  icon: Icons.today_rounded,
                  color: const Color(0xFF8B5CF6),
                  colorScheme: colorScheme,
                ),
                _StatCard(
                  label: context.l10n.analytics_stat_avg,
                  value: '${_avgOrderValue.toStringAsFixed(2)} PLN',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFFD97706),
                  colorScheme: colorScheme,
                ),
              ],
            );
          }),

          const SizedBox(height: 32),

          // ── Revenue chart ────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _sectionLabel(context.l10n.analytics_section_revenue, brandColors)),
              _RangeToggle(
                selected: _rangeDays,
                onChanged: (v) {
                  setState(() => _rangeDays = v);
                  _loadAnalytics();
                },
                brandColors: brandColors,
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RevenueChart(
            data: _revenueByDay,
            brandColors: brandColors,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 32),

          // ── Status breakdown ─────────────────────────────────────────
          _sectionLabel(context.l10n.analytics_section_status, brandColors),
          const SizedBox(height: 14),
          _StatusBreakdown(
            counts: _statusCounts,
            total: _totalOrders,
            brandColors: brandColors,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 32),

          // ── Popular items ────────────────────────────────────────────
          _sectionLabel(context.l10n.analytics_section_popular, brandColors),
          const SizedBox(height: 14),
          _PopularItems(
            itemCounts: _itemCounts,
            itemNames: _itemNames,
            brandColors: brandColors,
            colorScheme: colorScheme,
          ),
        ],
      ),
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
}

// ─── Range Toggle ─────────────────────────────────────────────────────────────

class _RangeToggle extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _RangeToggle({
    required this.selected,
    required this.onChanged,
    required this.brandColors,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [7, 30].map((days) {
          final bool isSelected = selected == days;
          return GestureDetector(
            onTap: () => onChanged(days),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? brandColors.navy : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '${days}d',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : brandColors.muted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Revenue Chart ────────────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  final Map<String, double> data;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _RevenueChart({
    required this.data,
    required this.brandColors,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    final maxValue = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxValue == 0 ? 1.0 : maxValue;

    // Show fewer labels when many days
    final int labelStep = entries.length > 14 ? 5 : (entries.length > 7 ? 2 : 1);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bars
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.asMap().entries.map((entry) {
                final double value = entry.value.value;
                final double heightRatio = value / effectiveMax;
                final bool hasValue = value > 0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Tooltip(
                      message: '${entry.value.key}: ${value.toStringAsFixed(2)} PLN',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            height: (heightRatio * 120).clamp(2.0, 120.0),
                            decoration: BoxDecoration(
                              color: hasValue
                                  ? brandColors.navy?.withValues(alpha: 0.85)
                                  : colorScheme.outline,
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
          // X-axis labels
          Row(
            children: entries.asMap().entries.map((entry) {
              final bool showLabel = entry.key % labelStep == 0;
              return Expanded(
                child: Text(
                  showLabel ? entry.value.key : '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: brandColors.muted),
                ),
              );
            }).toList(),
          ),
          if (maxValue == 0) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                context.l10n.analytics_no_revenue,
                style: TextStyle(fontSize: 12, color: brandColors.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Status Breakdown ─────────────────────────────────────────────────────────

class _StatusBreakdown extends StatelessWidget {
  final Map<String, int> counts;
  final int total;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _StatusBreakdown({
    required this.counts,
    required this.total,
    required this.brandColors,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Center(
          child: Text(context.l10n.analytics_no_orders,
              style: TextStyle(fontSize: 13, color: brandColors.muted)),
        ),
      );
    }

    final statuses = [
      ('normal', context.l10n.analytics_status_normal, brandColors.navy!),
      ('processing', context.l10n.analytics_status_processing, const Color(0xFF8B5CF6)),
      ('delivered', context.l10n.analytics_status_delivered, brandColors.accentGreen!),
      ('cancelled', context.l10n.analytics_status_cancelled, const Color(0xFFEF4444)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
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
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(s.$2,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Text('$count',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('(${(pct * 100).toInt()}%)',
                        style: TextStyle(
                            fontSize: 12, color: brandColors.muted)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: colorScheme.outline,
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

// ─── Popular Items ────────────────────────────────────────────────────────────

class _PopularItems extends StatelessWidget {
  final Map<String, int> itemCounts;
  final Map<String, String> itemNames;
  final BrandColors brandColors;
  final ColorScheme colorScheme;

  const _PopularItems({
    required this.itemCounts,
    required this.itemNames,
    required this.brandColors,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = (itemCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();

    if (sorted.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Center(
          child: Text(context.l10n.analytics_no_items,
              style: TextStyle(fontSize: 13, color: brandColors.muted)),
        ),
      );
    }

    final int maxCount = sorted.first.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final int rank = entry.key + 1;
          final String id = entry.value.key;
          final int count = entry.value.value;
          final String name = itemNames[id] ?? id;
          final double pct = count / maxCount;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: brandColors.muted),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(name,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(context.l10n.analytics_orders_count(count),
                              style: TextStyle(
                                  fontSize: 12, color: brandColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: colorScheme.outline,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              brandColors.navy!),
                          minHeight: 6,
                        ),
                      ),
                    ],
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

// ─── Stat Card ────────────────────────────────────────────────────────────────

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
                        fontSize: 16, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11, color: brandColors.muted)),
        ],
      ),
    );
  }
}