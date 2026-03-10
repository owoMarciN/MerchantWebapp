import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:user_app/extensions/extensions_import.dart';
import 'package:user_app/providers/global_stats_provider.dart';
import 'package:user_app/widgets/landing_widgets.dart';

class LandingPageScreen extends StatelessWidget {
  const LandingPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mount GlobalStatsProvider scoped to this screen only.
    // Disposed automatically when the user navigates away.
    return ChangeNotifierProvider(
      create: (_) => GlobalStatsProvider(),
      child: const _LandingPageView(),
    );
  }
}

class _LandingPageView extends StatelessWidget {
  const _LandingPageView();

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            LandingNav(activeRoute: '/'),
            _buildHero(context, brand, scheme),
            _buildLiveStats(context, brand, scheme),
            _buildLogoBanner(context, brand),
            _buildFeatures(context, brand, scheme),
            LandingCta(
              title: context.l10n.ready_to_grow,
              subtitle: context.l10n.join_restaurants,
              primaryLabel: context.l10n.register_now,
              primaryRoute: '/auth/register',
              secondaryLabel: context.l10n.see_how_it_works,
              secondaryRoute: '/how-it-works',
            ),
            const LandingFooter(),
          ],
        ),
      ),
    );
  }

  // -- Hero ----------------------------------------------------------------------

  Widget _buildHero(
      BuildContext context, BrandColors brand, ColorScheme scheme) {
    final bool isWide = context.isWide;
    final double h = isWide ? 60.0 : 24.0;
    final stats = context.watch<GlobalStatsProvider>();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 120 : 72),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: brand.navy?.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                  color:
                      brand.navy?.withValues(alpha: 0.4) ?? Colors.transparent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(brand.accentGreen ?? Colors.green),
                const SizedBox(width: 8),
                Text(
                  context.l10n.now_live_in,
                  style: TextStyle(
                      fontSize: 12,
                      color: brand.accentGreen,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              context.l10n.put_your_restaurant_on,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isWide ? 64 : 38,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Text(
              context.l10n.manage_your_menu,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, color: brand.muted, height: 1.6),
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              LandingPrimaryButton(
                label: context.l10n.register_your_restaurant,
                onTap: () => context.go('/auth/register'),
                large: true,
              ),
              LandingOutlineButton(
                label: context.l10n.see_how_it_works,
                onTap: () => context.go('/how-it-works'),
                large: true,
              ),
            ],
          ),
          const SizedBox(height: 80),
          _buildDashboardPreview(context, brand, scheme, stats),
        ],
      ),
    );
  }

  // -- Dashboard preview (live numbers) -------------------------------------

  Widget _buildDashboardPreview(BuildContext context, BrandColors brand,
      ColorScheme scheme, GlobalStatsProvider stats) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 900),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [brand.navy!, const Color(0xFF8B5CF6), brand.accentGreen!],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Fake browser chrome dots
            Row(
              children: [
                _dot(Colors.redAccent),
                const SizedBox(width: 6),
                _dot(Colors.orangeAccent),
                const SizedBox(width: 6),
                _dot(Colors.greenAccent),
              ],
            ),
            const SizedBox(height: 20),
            // Live stat cards — 2 on mobile, 4 on wide
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              final cards = [
                _previewStat(
                  context.l10n.orders_today,
                  stats.isLoading ? '—' : '${stats.todayOrders}',
                  brand.accentGreen!,
                  brand,
                  live: true,
                ),
                _previewStat(
                  context.l10n.total_orders,
                  stats.isLoading ? '—' : '${stats.totalOrders}',
                  brand.navy!,
                  brand,
                  live: true,
                ),
                _previewStat(
                  context.l10n.restaurants,
                  stats.isLoading ? '—' : '${stats.totalRestaurants}',
                  const Color(0xFF8B5CF6),
                  brand,
                  live: true,
                ),
                _previewStat(
                  context.l10n.menu_items,
                  stats.isLoading ? '—' : '${stats.totalItems}',
                  const Color(0xFFD97706),
                  brand,
                  live: true,
                ),
              ];

              if (isWide) {
                return Row(
                  children: cards
                      .map((c) => Expanded(
                          child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: c)))
                      .toList(),
                );
              }
              return Column(
                children: [
                  Row(children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 8),
                    Expanded(child: cards[1]),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: cards[2]),
                    const SizedBox(width: 8),
                    Expanded(child: cards[3]),
                  ]),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _previewStat(
    String label,
    String value,
    Color color,
    BrandColors brand, {
    bool live = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              if (live) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: brand.muted)),
        ],
      ),
    );
  }

  // -- Live stats strip -----------------------------------------------------------------------

  Widget _buildLiveStats(
      BuildContext context, BrandColors brand, ColorScheme scheme) {
    final bool isWide = context.isWide;
    final double h = isWide ? 60.0 : 24.0;
    final stats = context.watch<GlobalStatsProvider>();

    final items = [
      _LiveStat(
        icon: Icons.storefront_rounded,
        value: stats.isLoading ? '—' : '${stats.totalRestaurants}',
        label: context.l10n.restaurants_on_platform,
        color: brand.navy!,
      ),
      _LiveStat(
        icon: Icons.receipt_long_rounded,
        value: stats.isLoading ? '—' : '${stats.totalOrders}',
        label: context.l10n.orders_placed,
        color: brand.accentGreen!,
      ),
      _LiveStat(
        icon: Icons.restaurant_menu_rounded,
        value: stats.isLoading ? '—' : '${stats.totalMenus}',
        label: context.l10n.menus_published,
        color: const Color(0xFF8B5CF6),
      ),
      _LiveStat(
        icon: Icons.fastfood_rounded,
        value: stats.isLoading ? '—' : '${stats.totalItems}',
        label: context.l10n.items_available,
        color: const Color(0xFFD97706),
      ),
      _LiveStat(
        icon: Icons.today_rounded,
        value: stats.isLoading ? '—' : '${stats.todayOrders}',
        label: context.l10n.orders_today,
        color: const Color(0xFFEF4444),
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 56 : 40),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.symmetric(horizontal: BorderSide(color: scheme.outline)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: brand.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.live_platform_stats,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: brand.muted,
                    letterSpacing: 1.8),
              ),
            ],
          ),
          const SizedBox(height: 32),
          LayoutBuilder(builder: (context, constraints) {
            // 5 cols on wide, 2 cols wrapped on mobile
            if (constraints.maxWidth > 700) {
              return Row(
                children: items
                    .map((s) => Expanded(
                        child: _LiveStatTile(
                            stat: s, brand: brand, scheme: scheme)))
                    .toList(),
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items
                  .map((s) => SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _LiveStatTile(
                            stat: s, brand: brand, scheme: scheme),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  // -- Logo banner ----------------------------------------------------------------------------

  Widget _buildLogoBanner(BuildContext context, BrandColors brand) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
          border: Border(
              bottom:
                  BorderSide(color: Theme.of(context).colorScheme.outline))),
      child: Column(
        children: [
          Text(context.l10n.trusted_by_restaurants,
              style: TextStyle(
                  fontSize: 10, color: brand.muted, letterSpacing: 2)),
          const SizedBox(height: 24),
          // Add your restaurant logo list here
        ],
      ),
    );
  }

  // -- Features -------------------------------------------------------------------------------

  Widget _buildFeatures(
      BuildContext context, BrandColors brand, ColorScheme scheme) {
    final bool isWide = context.isWide;
    final double h = isWide ? 60.0 : 24.0;

    final features = [
      _Feature(Icons.restaurant_menu_rounded, context.l10n.digital_menu,
          context.l10n.your_menu_goes_live_instantly, brand.navy!),
      _Feature(Icons.image_rounded, context.l10n.custom_banners,
          context.l10n.full_creative_control, const Color(0xFF8B5CF6)),
      _Feature(Icons.bar_chart_rounded, context.l10n.sales_analytics,
          context.l10n.track_peak_hours, brand.accentGreen!),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: 100),
      child: Column(
        children: [
          LandingSectionLabel(context.l10n.upper_features),
          const SizedBox(height: 60),
          isWide
              ? Row(
                  children: features
                      .map((f) => Expanded(
                          child: _FeatureCard(
                              feature: f, brand: brand, scheme: scheme)))
                      .toList())
              : Column(
                  children: features
                      .map((f) => _FeatureCard(
                          feature: f, brand: brand, scheme: scheme))
                      .toList()),
        ],
      ),
    );
  }
}

// -- Live stat tile -----------------------------------------------------------------------------

class _LiveStat {
  final IconData icon;
  final String value, label;
  final Color color;
  const _LiveStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}

class _LiveStatTile extends StatelessWidget {
  final _LiveStat stat;
  final BrandColors brand;
  final ColorScheme scheme;
  const _LiveStatTile(
      {required this.stat, required this.brand, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stat.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, color: stat.color, size: 20),
          const SizedBox(height: 12),
          Text(stat.value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: stat.color,
                  height: 1)),
          const SizedBox(height: 4),
          Text(stat.label,
              style: TextStyle(fontSize: 12, color: brand.muted, height: 1.4)),
        ],
      ),
    );
  }
}

// -- Feature card -------------------------------------------------------------------------------

class _Feature {
  final IconData icon;
  final String title, desc;
  final Color color;
  const _Feature(this.icon, this.title, this.desc, this.color);
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  final BrandColors brand;
  final ColorScheme scheme;
  const _FeatureCard(
      {required this.feature, required this.brand, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(feature.icon, color: feature.color),
            const SizedBox(width: 16),
            Text(feature.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(feature.desc,
              style: TextStyle(color: brand.muted, fontSize: 13)),
        ],
      ),
    );
  }
}
