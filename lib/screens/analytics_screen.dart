import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/extensions/responsive_ext.dart';
import 'package:user_app/providers/local_stats_provider.dart';
import 'package:user_app/widgets/progress_bar.dart';
import 'package:user_app/providers/menu_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _rangeDays = 7;

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    // Listen to the provider
    final stats = context.watch<LocalStatsProvider>();
    final menu = context.watch<MenuProvider>();

    if (stats.isLoading || menu.isLoading) {
      return Center(child: circularProgress());
    }

    // Determine values based on selected range
    final displayRevenue =
        _rangeDays == 7 ? stats.last7dRevenue : stats.last30dRevenue;
    final displayOrders =
        _rangeDays == 7 ? stats.last7dOrders : stats.last30dOrders;
    final chartData = stats.revenueForRange(_rangeDays);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('AT A GLANCE', brandColors),
          const SizedBox(height: 14),
          _buildStatGrid(
              displayRevenue, displayOrders, stats, brandColors, colorScheme),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _sectionLabel('REVENUE OVER TIME', brandColors)),
              _RangeToggle(
                selected: _rangeDays,
                onChanged: (v) => setState(() => _rangeDays = v),
                brandColors: brandColors,
                colorScheme: colorScheme,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RevenueChart(
            data: chartData,
            brandColors: brandColors,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 32),
          _sectionLabel('ORDER STATUS BREAKDOWN', brandColors),
          const SizedBox(height: 14),
          _StatusBreakdown(
            counts: stats.statusCounts,
            total: stats.totalOrders,
            brandColors: brandColors,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 32),
          _sectionLabel('MOST ORDERED ITEMS', brandColors),
          const SizedBox(height: 14),
          _PopularItems(
            itemCounts: stats.itemCounts,
            itemNames: menu.itemNames,
            brandColors: brandColors,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(double rev, int ord, LocalStatsProvider stats,
      BrandColors brands, ColorScheme scheme) {
    return LayoutBuilder(builder: (context, constraints) {
      final int cols = context.gridCols421;

      return GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 90,
        ),
        children: [
          _StatCard(
            label: 'Revenue (${_rangeDays}d)',
            value: '${rev.toStringAsFixed(2)} PLN',
            icon: Icons.payments_rounded,
            color: brands.accentGreen!,
            colorScheme: scheme,
          ),
          _StatCard(
            label: 'Orders (${_rangeDays}d)',
            value: '$ord',
            icon: Icons.shopping_bag_rounded,
            color: brands.navy!,
            colorScheme: scheme,
          ),
          _StatCard(
            label: 'Today\'s Sales',
            value: '${stats.todayRevenue.toStringAsFixed(2)} PLN',
            icon: Icons.today_rounded,
            color: const Color(0xFF8B5CF6),
            colorScheme: scheme,
          ),
          _StatCard(
            label: 'Avg Order',
            value: '${stats.avgOrderValue.toStringAsFixed(2)} PLN',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFFD97706),
            colorScheme: scheme,
          ),
        ],
      );
    });
  }

  Widget _sectionLabel(String text, BrandColors brandColors) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: brandColors.muted,
          letterSpacing: 1.2),
    );
  }
}

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
    final int labelStep =
        entries.length > 14 ? 5 : (entries.length > 7 ? 2 : 1);

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
                      message:
                          '${entry.value.key}: ${value.toStringAsFixed(2)} PLN',
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
                'No revenue data for this period',
                style: TextStyle(fontSize: 12, color: brandColors.muted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

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
          child: Text('No orders in this period',
              style: TextStyle(fontSize: 13, color: brandColors.muted)),
        ),
      );
    }

    final statuses = [
      ('normal', 'Normal', brandColors.navy!),
      ('processing', 'Processing', const Color(0xFF8B5CF6)),
      ('delivered', 'Delivered', brandColors.accentGreen!),
      ('cancelled', 'Cancelled', const Color(0xFFEF4444)),
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
                        style:
                            TextStyle(fontSize: 12, color: brandColors.muted)),
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
      return _buildEmptyState();
    }

    final int maxCount = sorted.first.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final int index = entry.key;
          final int rank = index + 1;
          final String id = entry.value.key;
          final int count = entry.value.value;
          final String name = itemNames[id] ?? id;
          final double pct = maxCount > 0 ? count / maxCount : 0;

          return Padding(
            padding:
                EdgeInsets.only(bottom: index == sorted.length - 1 ? 0 : 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rank Badge
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: rank <= 3
                        ? brandColors.navy?.withValues(alpha: 0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: rank <= 3 ? brandColors.navy : brandColors.muted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Item Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$count orders',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: brandColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            brandColors.navy ?? colorScheme.primary,
                          ),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: brandColors.muted, size: 32),
          const SizedBox(height: 12),
          Text(
            'No item data for this period',
            style: TextStyle(fontSize: 13, color: brandColors.muted),
          ),
        ],
      ),
    );
  }
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
