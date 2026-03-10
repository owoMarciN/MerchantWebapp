import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/extensions/extensions_import.dart';
import 'package:user_app/extensions/responsive_ext.dart';
import 'package:user_app/widgets/landing_widgets.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  int _ordersPerDay = 20;
  double _avgOrderValue = 45.0;

  ({double rate, String tierName, Color tierColor}) _getTier(
      int monthlyOrders, BrandColors brand, BuildContext context) {
    if (monthlyOrders <= 100) {
      return (
        rate: 0.10,
        tierName: context.l10n.pricing_tier_name_starter,
        tierColor: brand.muted!
      );
    } else if (monthlyOrders <= 500) {
      return (
        rate: 0.08,
        tierName: context.l10n.pricing_tier_name_growing,
        tierColor: brand.navy!
      );
    } else if (monthlyOrders <= 1500) {
      return (
        rate: 0.06,
        tierName: context.l10n.pricing_tier_name_established,
        tierColor: const Color(0xFF8B5CF6),
      );
    } else {
      return (
        rate: 0.04,
        tierName: context.l10n.pricing_tier_name_partner,
        tierColor: brand.accentGreen!
      );
    }
  }

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
            LandingNav(activeRoute: '/pricing'),
            _buildHero(context, brand, isWide, h),
            _buildCommissionExplainer(context, brand, scheme, isWide, h),
            _buildCalculator(context, brand, scheme, isWide, h),
            _buildTiers(context, brand, scheme, isWide, h),
            _buildFaq(context, brand, scheme, isWide, h),
            LandingCta(
              title: context.l10n.pricing_cta_title,
              subtitle: context.l10n.pricing_cta_subtitle,
              primaryLabel: context.l10n.pricing_cta_primary,
              primaryRoute: '/auth/register',
            ),
            const LandingFooter(),
          ],
        ),
      ),
    );
  }

  // -- Hero ------------------------------------------------------------------

  Widget _buildHero(
      BuildContext context, BrandColors brand, bool isWide, double h) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 100 : 64),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: brand.accentGreen?.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                  color: brand.accentGreen?.withValues(alpha: 0.3) ??
                      Colors.transparent),
            ),
            child: Text(context.l10n.pricing_hero_badge,
                style: TextStyle(
                    fontSize: 12,
                    color: brand.accentGreen,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              context.l10n.pricing_hero_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isWide ? 58 : 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1),
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              context.l10n.pricing_hero_subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: brand.muted, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // -- Commission explainer --------------------------------------------------

  Widget _buildCommissionExplainer(BuildContext context, BrandColors brand,
      ColorScheme scheme, bool isWide, double h) {
    final steps = [
      _CommissionStepData(
        number: '1',
        title: context.l10n.pricing_step1_title,
        description: context.l10n.pricing_step1_desc,
        icon: Icons.shopping_bag_rounded,
        color: brand.navy!,
      ),
      _CommissionStepData(
        number: '2',
        title: context.l10n.pricing_step2_title,
        description: context.l10n.pricing_step2_desc,
        icon: Icons.restaurant_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      _CommissionStepData(
        number: '3',
        title: context.l10n.pricing_step3_title,
        description: context.l10n.pricing_step3_desc,
        icon: Icons.payments_rounded,
        color: brand.accentGreen!,
      ),
    ];

    return Container(
      color: scheme.surface,
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 72 : 48),
      child: Column(
        children: [
          LandingSectionLabel(context.l10n.pricing_section_fee),
          const SizedBox(height: 48),
          LayoutBuilder(builder: (context, constraints) {
            final isThreeCol = constraints.maxWidth > 700;
            if (isThreeCol) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _CommissionStepCard(
                          data: steps[0], brand: brand, scheme: scheme)),
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: brand.muted, size: 20),
                  ),
                  Expanded(
                      child: _CommissionStepCard(
                          data: steps[1], brand: brand, scheme: scheme)),
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: brand.muted, size: 20),
                  ),
                  Expanded(
                      child: _CommissionStepCard(
                          data: steps[2], brand: brand, scheme: scheme)),
                ],
              );
            }
            return Column(
              children: steps
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CommissionStepCard(
                            data: s, brand: brand, scheme: scheme),
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  // -- Calculator ------------------------------------------------------------

  Widget _buildCalculator(BuildContext context, BrandColors brand,
      ColorScheme scheme, bool isWide, double h) {
    final int monthlyOrders = _ordersPerDay * 30;
    final tier = _getTier(monthlyOrders, brand, context);

    final double dailyRevenue = _ordersPerDay * _avgOrderValue;
    final double dailyFee = dailyRevenue * tier.rate;
    final double dailyNet = dailyRevenue - dailyFee;
    final double monthlyNet = dailyNet * 30;
    final String pctLabel = '${(tier.rate * 100).toStringAsFixed(0)}%';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 72 : 48),
      child: Column(
        children: [
          LandingSectionLabel(context.l10n.pricing_section_calculator),
          const SizedBox(height: 16),
          Text(context.l10n.pricing_calculator_title,
              style: TextStyle(
                  fontSize: isWide ? 32 : 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outline),
              ),
              child: Column(
                children: [
                  _SliderRow(
                    label: context.l10n.pricing_slider_orders_label,
                    value: _ordersPerDay.toDouble(),
                    min: 5,
                    max: 200,
                    divisions: 195,
                    displayValue: context.l10n.pricing_slider_orders_value(
                        _ordersPerDay, monthlyOrders),
                    onChanged: (v) => setState(() => _ordersPerDay = v.round()),
                    brand: brand,
                    color: brand.navy!,
                  ),
                  const SizedBox(height: 28),
                  _SliderRow(
                    label: context.l10n.pricing_slider_avg_label,
                    value: _avgOrderValue,
                    min: 15,
                    max: 200,
                    divisions: 37,
                    displayValue: context.l10n.pricing_slider_avg_value(
                        _avgOrderValue.toStringAsFixed(0)),
                    onChanged: (v) => setState(() => _avgOrderValue = v),
                    brand: brand,
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 24),

                  // Active tier badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: tier.tierColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: tier.tierColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: tier.tierColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          context.l10n.pricing_tier_badge(
                              tier.tierName, pctLabel),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: tier.tierColor),
                        ),
                        const Spacer(),
                        Text(
                          context.l10n.pricing_tier_monthly(monthlyOrders),
                          style:
                              TextStyle(fontSize: 11, color: tier.tierColor),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Divider(color: scheme.outline),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                          child: _CalcResult(
                        label: context.l10n.pricing_calc_revenue_label,
                        value: '${dailyRevenue.toStringAsFixed(0)} PLN',
                        sub: context.l10n.pricing_calc_revenue_sub,
                        color: brand.muted!,
                        brand: brand,
                        scheme: scheme,
                      )),
                      Expanded(
                          child: _CalcResult(
                        label: context.l10n.pricing_calc_fee_label(pctLabel),
                        value: '− ${dailyFee.toStringAsFixed(0)} PLN',
                        sub: context.l10n.pricing_calc_fee_sub,
                        color: const Color(0xFFEF4444),
                        brand: brand,
                        scheme: scheme,
                      )),
                      Expanded(
                          child: _CalcResult(
                        label: context.l10n.pricing_calc_keep_label,
                        value: '${dailyNet.toStringAsFixed(0)} PLN/day',
                        sub:
                            '≈ ${monthlyNet.toStringAsFixed(0)} PLN/month',
                        color: brand.accentGreen!,
                        brand: brand,
                        scheme: scheme,
                        highlight: true,
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.pricing_calc_disclaimer,
                    style: TextStyle(fontSize: 11, color: brand.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Tiers -----------------------------------------------------------------

  Widget _buildTiers(BuildContext context, BrandColors brand,
      ColorScheme scheme, bool isWide, double h) {
    final brand = Theme.of(context).extension<BrandColors>()!;
    final tiers = [
      _TierData(
        label: context.l10n.pricing_tier_starter_label,
        range: context.l10n.pricing_tier_starter_range,
        rate: '10%',
        description: context.l10n.pricing_tier_starter_desc,
        color: brand.muted!,
      ),
      _TierData(
        label: context.l10n.pricing_tier_growing_label,
        range: context.l10n.pricing_tier_growing_range,
        rate: '8%',
        description: context.l10n.pricing_tier_growing_desc,
        color: brand.navy!,
      ),
      _TierData(
        label: context.l10n.pricing_tier_established_label,
        range: context.l10n.pricing_tier_established_range,
        rate: '6%',
        description: context.l10n.pricing_tier_established_desc,
        color: const Color(0xFF8B5CF6),
      ),
      _TierData(
        label: context.l10n.pricing_tier_partner_label,
        range: context.l10n.pricing_tier_partner_range,
        rate: '4%',
        description: context.l10n.pricing_tier_partner_desc,
        color: brand.accentGreen!,
      ),
    ];

    return Container(
      color: scheme.surface,
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 72 : 48),
      child: Column(
        children: [
          LandingSectionLabel(context.l10n.pricing_section_tiers),
          const SizedBox(height: 16),
          Text(context.l10n.pricing_tiers_title,
              style: TextStyle(
                  fontSize: isWide ? 32 : 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(
            context.l10n.pricing_tiers_subtitle,
            style: TextStyle(fontSize: 14, color: brand.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: tiers
                  .asMap()
                  .entries
                  .map((e) => _TierRow(
                        data: e.value,
                        isLast: e.key == tiers.length - 1,
                        brand: brand,
                        scheme: scheme,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // -- FAQ -------------------------------------------------------------------

  Widget _buildFaq(BuildContext context, BrandColors brand, ColorScheme scheme,
      bool isWide, double h) {
    final faqs = [
      _Faq(context.l10n.pricing_faq1_q, context.l10n.pricing_faq1_a),
      _Faq(context.l10n.pricing_faq2_q, context.l10n.pricing_faq2_a),
      _Faq(context.l10n.pricing_faq3_q, context.l10n.pricing_faq3_a),
      _Faq(context.l10n.pricing_faq4_q, context.l10n.pricing_faq4_a),
      _Faq(context.l10n.pricing_faq5_q, context.l10n.pricing_faq5_a),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 72 : 48),
      child: Column(
        children: [
          LandingSectionLabel(context.l10n.pricing_section_faq),
          const SizedBox(height: 16),
          Text(context.l10n.pricing_faq_title,
              style: TextStyle(
                  fontSize: isWide ? 32 : 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: faqs
                  .map((f) => _FaqTile(faq: f, brand: brand, scheme: scheme))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Commission step card -----------------------------------------------------

class _CommissionStepCard extends StatelessWidget {
  final _CommissionStepData data;
  final BrandColors brand;
  final ColorScheme scheme;
  const _CommissionStepCard(
      {required this.data, required this.brand, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(data.number,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: data.color)),
                ),
              ),
              const SizedBox(width: 10),
              Icon(data.icon, color: data.color, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(data.title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(data.description,
              style: TextStyle(fontSize: 12, color: brand.muted, height: 1.5)),
        ],
      ),
    );
  }
}

// -- Slider row ---------------------------------------------------------------

class _SliderRow extends StatelessWidget {
  final String label, displayValue;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final BrandColors brand;
  final Color color;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
    required this.brand,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(displayValue,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.15),
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// -- Calc result --------------------------------------------------------------

class _CalcResult extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  final BrandColors brand;
  final ColorScheme scheme;
  final bool highlight;

  const _CalcResult({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.brand,
    required this.scheme,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border:
            highlight ? Border.all(color: color.withValues(alpha: 0.25)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: brand.muted)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, color: brand.muted)),
        ],
      ),
    );
  }
}

// -- Tier row -----------------------------------------------------------------

class _TierRow extends StatelessWidget {
  final _TierData data;
  final bool isLast;
  final BrandColors brand;
  final ColorScheme scheme;

  const _TierRow({
    required this.data,
    required this.isLast,
    required this.brand,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: data.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(data.label,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(data.range,
                          style: TextStyle(
                              fontSize: 10,
                              color: data.color,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(data.description,
                    style: TextStyle(fontSize: 12, color: brand.muted)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(data.rate,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: data.color)),
        ],
      ),
    );
  }
}

// -- FAQ tile -----------------------------------------------------------------

class _FaqTile extends StatefulWidget {
  final _Faq faq;
  final BrandColors brand;
  final ColorScheme scheme;
  const _FaqTile(
      {required this.faq, required this.brand, required this.scheme});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _open
                ? widget.brand.navy?.withValues(alpha: 0.4) ??
                    widget.scheme.outline
                : widget.scheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.faq.question,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Icon(
                    _open ? Icons.remove_rounded : Icons.add_rounded,
                    size: 18,
                    color: widget.brand.muted,
                  ),
                ],
              ),
              if (_open) ...[
                const SizedBox(height: 12),
                Text(widget.faq.answer,
                    style: TextStyle(
                        fontSize: 13, color: widget.brand.muted, height: 1.6)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// -- Data models --------------------------------------------------------------

class _CommissionStepData {
  final String number, title, description;
  final IconData icon;
  final Color color;
  const _CommissionStepData({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _TierData {
  final String label, range, rate, description;
  final Color color;
  const _TierData({
    required this.label,
    required this.range,
    required this.rate,
    required this.description,
    required this.color,
  });
}

class _Faq {
  final String question, answer;
  const _Faq(this.question, this.answer);
}