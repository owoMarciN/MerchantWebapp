import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
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

  // Returns commission rate, tier name and color based on monthly order count
  ({double rate, String tierName, Color tierColor}) _getTier(
      int monthlyOrders, BrandColors brand) {
    if (monthlyOrders <= 100) {
      return (rate: 0.10, tierName: 'Starter', tierColor: brand.muted!);
    } else if (monthlyOrders <= 500) {
      return (rate: 0.08, tierName: 'Growing', tierColor: brand.navy!);
    } else if (monthlyOrders <= 1500) {
      return (
        rate: 0.06,
        tierName: 'Established',
        tierColor: const Color(0xFF8B5CF6),
      );
    } else {
      return (rate: 0.04, tierName: 'Partner', tierColor: brand.accentGreen!);
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
              title: 'Start for free today.',
              subtitle: 'No fees until your first order.',
              primaryLabel: 'Register Your Restaurant',
              primaryRoute: '/auth/register',
            ),
            const LandingFooter(),
          ],
        ),
      ),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────

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
            child: Text('No monthly fees. Ever.',
                style: TextStyle(
                    fontSize: 12,
                    color: brand.accentGreen,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              'Pay only when\nyou earn.',
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
              'Freequick charges a small commission on completed orders only. If you don\'t earn, you don\'t pay.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  color: brand.muted,
                  height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // ── Commission explainer ──────────────────────────────────────────────────

  Widget _buildCommissionExplainer(BuildContext context, BrandColors brand,
      ColorScheme scheme, bool isWide, double h) {
    final steps = [
      _CommissionStepData(
        number: '1',
        title: 'Customer places an order',
        description:
            'They browse your menu, add items, and pay through the app.',
        icon: Icons.shopping_bag_rounded,
        color: brand.navy!,
      ),
      _CommissionStepData(
        number: '2',
        title: 'You prepare and deliver',
        description:
            'You confirm the order, prepare it, and mark it as delivered.',
        icon: Icons.restaurant_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      _CommissionStepData(
        number: '3',
        title: 'We take a small cut',
        description:
            'A commission is deducted from the order value. The rest goes to you.',
        icon: Icons.payments_rounded,
        color: brand.accentGreen!,
      ),
    ];

    return Container(
      color: scheme.surface,
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 72 : 48),
      child: Column(
        children: [
          LandingSectionLabel('HOW THE FEE WORKS'),
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

  // ── Calculator ────────────────────────────────────────────────────────────

  Widget _buildCalculator(BuildContext context, BrandColors brand,
      ColorScheme scheme, bool isWide, double h) {
    final int monthlyOrders = _ordersPerDay * 30;
    final tier = _getTier(monthlyOrders, brand);

    final double dailyRevenue = _ordersPerDay * _avgOrderValue;
    final double dailyFee = dailyRevenue * tier.rate;
    final double dailyNet = dailyRevenue - dailyFee;
    final double monthlyNet = dailyNet * 30;
    final String pctLabel = '${(tier.rate * 100).toStringAsFixed(0)}%';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 72 : 48),
      child: Column(
        children: [
          LandingSectionLabel('ESTIMATE YOUR EARNINGS'),
          const SizedBox(height: 16),
          Text('See what you keep.',
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
                    label: 'Orders per day',
                    value: _ordersPerDay.toDouble(),
                    min: 5,
                    max: 200,
                    divisions: 195,
                    displayValue:
                        '$_ordersPerDay orders/day · $monthlyOrders/month',
                    onChanged: (v) =>
                        setState(() => _ordersPerDay = v.round()),
                    brand: brand,
                    color: brand.navy!,
                  ),
                  const SizedBox(height: 28),
                  _SliderRow(
                    label: 'Average order value',
                    value: _avgOrderValue,
                    min: 15,
                    max: 200,
                    divisions: 37,
                    displayValue:
                        '${_avgOrderValue.toStringAsFixed(0)} PLN',
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
                          '${tier.tierName} tier — $pctLabel commission',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: tier.tierColor),
                        ),
                        const Spacer(),
                        Text(
                          '$monthlyOrders orders/month',
                          style: TextStyle(
                              fontSize: 11, color: tier.tierColor),
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
                        label: 'Daily revenue',
                        value:
                            '${dailyRevenue.toStringAsFixed(0)} PLN',
                        sub: 'before commission',
                        color: brand.muted!,
                        brand: brand,
                        scheme: scheme,
                      )),
                      Expanded(
                          child: _CalcResult(
                        label: 'Freequick fee ($pctLabel)',
                        value:
                            '− ${dailyFee.toStringAsFixed(0)} PLN',
                        sub: 'per day',
                        color: const Color(0xFFEF4444),
                        brand: brand,
                        scheme: scheme,
                      )),
                      Expanded(
                          child: _CalcResult(
                        label: 'You keep',
                        value:
                            '${dailyNet.toStringAsFixed(0)} PLN/day',
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
                    'Commission is only charged on completed, delivered orders.',
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

  // ── Tiers ─────────────────────────────────────────────────────────────────

  Widget _buildTiers(BuildContext context, BrandColors brand,
      ColorScheme scheme, bool isWide, double h) {
    final brand = Theme.of(context).extension<BrandColors>()!;
    final tiers = [
      _TierData(
        label: 'Starter',
        range: '0 – 100 orders/month',
        rate: '10%',
        description: 'Get started with no upfront cost.',
        color: brand.muted!,
      ),
      _TierData(
        label: 'Growing',
        range: '101 – 500 orders/month',
        rate: '8%',
        description: 'Lower rate as you build your customer base.',
        color: brand.navy!,
      ),
      _TierData(
        label: 'Established',
        range: '501 – 1 500 orders/month',
        rate: '6%',
        description: 'Rewarding consistent high-volume restaurants.',
        color: const Color(0xFF8B5CF6),
      ),
      _TierData(
        label: 'Partner',
        range: '1 500+ orders/month',
        rate: '4%',
        description: 'Our best rate for our highest-volume partners.',
        color: brand.accentGreen!,
      ),
    ];

    return Container(
      color: scheme.surface,
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 72 : 48),
      child: Column(
        children: [
          LandingSectionLabel('COMMISSION TIERS'),
          const SizedBox(height: 16),
          Text('More orders, lower rate.',
              style: TextStyle(
                  fontSize: isWide ? 32 : 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(
            'As your restaurant grows, your commission rate goes down automatically.',
            style: TextStyle(fontSize: 14, color: brand.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: tiers.asMap().entries.map((e) => _TierRow(
                    data: e.value,
                    isLast: e.key == tiers.length - 1,
                    brand: brand,
                    scheme: scheme,
                  )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── FAQ ───────────────────────────────────────────────────────────────────

  Widget _buildFaq(BuildContext context, BrandColors brand, ColorScheme scheme,
      bool isWide, double h) {
    final faqs = [
      _Faq('Are there any setup or monthly fees?',
          'No. Freequick charges zero setup fees and zero monthly fees. You only pay commission on completed orders.'),
      _Faq('When does the commission get deducted?',
          'Commission is calculated at the time an order is marked as delivered. It is deducted from your payout balance automatically.'),
      _Faq('How often do I get paid?',
          'Payouts are processed weekly to your registered IBAN bank account. You can track your balance in real-time on the dashboard.'),
      _Faq('What happens if an order is cancelled?',
          'Cancelled orders are not charged commission. You only pay for successful, completed deliveries.'),
      _Faq('Can I change my bank account details later?',
          'Yes. You can update your IBAN at any time in the Settings section of your dashboard.'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 72 : 48),
      child: Column(
        children: [
          LandingSectionLabel('FREQUENTLY ASKED'),
          const SizedBox(height: 16),
          Text('Common questions.',
              style: TextStyle(
                  fontSize: isWide ? 32 : 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: faqs
                  .map((f) =>
                      _FaqTile(faq: f, brand: brand, scheme: scheme))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Commission step card ──────────────────────────────────────────────────────

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
              style:
                  TextStyle(fontSize: 12, color: brand.muted, height: 1.5)),
        ],
      ),
    );
  }
}

// ── Slider row ────────────────────────────────────────────────────────────────

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
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(displayValue,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
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

// ── Calc result ───────────────────────────────────────────────────────────────

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

// ── Tier row ──────────────────────────────────────────────────────────────────

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

// ── FAQ tile ──────────────────────────────────────────────────────────────────

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
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        fontSize: 13,
                        color: widget.brand.muted,
                        height: 1.6)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

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