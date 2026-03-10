import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/extensions/extensions_import.dart';
import 'package:user_app/extensions/responsive_ext.dart';
import 'package:user_app/widgets/landing_widgets.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final isWide = context.isWide;
    final h = isWide ? 60.0 : 24.0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            LandingNav(activeRoute: '/how-it-works'),
            _buildHero(context, brand, scheme, isWide, h),
            _buildSteps(context, brand, scheme, isWide, h),
            _buildFeatureGrid(context, brand, scheme, isWide, h),
            LandingCta(
              title: context.l10n.hiw_cta_title,
              subtitle: context.l10n.hiw_cta_subtitle,
              primaryLabel: context.l10n.hiw_cta_primary,
              primaryRoute: '/auth/register',
              secondaryLabel: context.l10n.hiw_cta_secondary,
              secondaryRoute: '/pricing',
            ),
            const LandingFooter(),
          ],
        ),
      ),
    );
  }

  // -- Hero ------------------------------------------------------------------

  Widget _buildHero(BuildContext context, BrandColors brand, ColorScheme scheme,
      bool isWide, double h) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 100 : 64),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: brand.navy?.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                  color:
                      brand.navy?.withValues(alpha: 0.3) ?? Colors.transparent),
            ),
            child: Text(context.l10n.hiw_hero_badge,
                style: TextStyle(
                    fontSize: 12,
                    color: brand.navy,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              context.l10n.hiw_hero_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isWide ? 58 : 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1),
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(
              context.l10n.hiw_hero_subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: brand.muted, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // -- Steps -----------------------------------------------------------------

  Widget _buildSteps(BuildContext context, BrandColors brand,
      ColorScheme scheme, bool isWide, double h) {
    final steps = [
      _Step(
        number: '01',
        title: context.l10n.hiw_step1_title,
        description: context.l10n.hiw_step1_desc,
        icon: Icons.person_add_rounded,
        color: brand.navy!,
      ),
      _Step(
        number: '02',
        title: context.l10n.hiw_step2_title,
        description: context.l10n.hiw_step2_desc,
        icon: Icons.storefront_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      _Step(
        number: '03',
        title: context.l10n.hiw_step3_title,
        description: context.l10n.hiw_step3_desc,
        icon: Icons.restaurant_menu_rounded,
        color: brand.accentGreen!,
      ),
      _Step(
        number: '04',
        title: context.l10n.hiw_step4_title,
        description: context.l10n.hiw_step4_desc,
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFD97706),
      ),
      _Step(
        number: '05',
        title: context.l10n.hiw_step5_title,
        description: context.l10n.hiw_step5_desc,
        icon: Icons.account_balance_rounded,
        color: const Color(0xFFEF4444),
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 80 : 48),
      child: Column(
        children: [
          LandingSectionLabel(context.l10n.hiw_section_process),
          const SizedBox(height: 56),
          ...steps.asMap().entries.map((entry) => _StepRow(
                step: entry.value,
                isLast: entry.key == steps.length - 1,
                isWide: isWide,
                brand: brand,
                scheme: scheme,
              )),
        ],
      ),
    );
  }

  // -- Feature grid ----------------------------------------------------------

  Widget _buildFeatureGrid(BuildContext context, BrandColors brand,
      ColorScheme scheme, bool isWide, double h) {
    final items = [
      _GridItem(Icons.bolt_rounded,          context.l10n.hiw_feature1_title, context.l10n.hiw_feature1_desc, brand.navy!),
      _GridItem(Icons.analytics_rounded,     context.l10n.hiw_feature2_title, context.l10n.hiw_feature2_desc, const Color(0xFF8B5CF6)),
      _GridItem(Icons.image_rounded,         context.l10n.hiw_feature3_title, context.l10n.hiw_feature3_desc, brand.accentGreen!),
      _GridItem(Icons.lock_rounded,          context.l10n.hiw_feature4_title, context.l10n.hiw_feature4_desc, const Color(0xFFD97706)),
      _GridItem(Icons.devices_rounded,       context.l10n.hiw_feature5_title, context.l10n.hiw_feature5_desc, const Color(0xFFEF4444)),
      _GridItem(Icons.support_agent_rounded, context.l10n.hiw_feature6_title, context.l10n.hiw_feature6_desc, const Color(0xFF0EA5E9)),
    ];

    return Container(
      color: scheme.surface,
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 80 : 48),
      child: Column(
        children: [
          LandingSectionLabel(context.l10n.hiw_section_features),
          const SizedBox(height: 16),
          Text(context.l10n.hiw_features_title,
              style: TextStyle(
                  fontSize: isWide ? 36 : 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 48),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth > 700 ? 3 : 1;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 160,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) =>
                  _GridCard(item: items[i], brand: brand, scheme: scheme),
            );
          }),
        ],
      ),
    );
  }
}

// -- Step row -----------------------------------------------------------------

class _StepRow extends StatelessWidget {
  final _Step step;
  final bool isLast;
  final bool isWide;
  final BrandColors brand;
  final ColorScheme scheme;

  const _StepRow({
    required this.step,
    required this.isLast,
    required this.isWide,
    required this.brand,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: step.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: step.color.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Center(
                    child: Text(step.number,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: step.color)),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            step.color.withValues(alpha: 0.3),
                            step.color.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 40),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(step.title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(step.description,
                            style: TextStyle(
                                fontSize: 14, color: brand.muted, height: 1.6)),
                      ],
                    ),
                  ),
                  if (isWide) ...[
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: step.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(step.icon, color: step.color, size: 24),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Grid card ----------------------------------------------------------------

class _GridCard extends StatelessWidget {
  final _GridItem item;
  final BrandColors brand;
  final ColorScheme scheme;
  const _GridCard(
      {required this.item, required this.brand, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(item.title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(item.desc,
              style: TextStyle(fontSize: 12, color: brand.muted, height: 1.5)),
        ],
      ),
    );
  }
}

// -- Data models --------------------------------------------------------------

class _Step {
  final String number, title, description;
  final IconData icon;
  final Color color;
  const _Step({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _GridItem {
  final IconData icon;
  final String title, desc;
  final Color color;
  const _GridItem(this.icon, this.title, this.desc, this.color);
}