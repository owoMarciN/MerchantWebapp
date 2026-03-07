import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
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
              title: 'Ready to get started?',
              subtitle: 'Join restaurants already on Freequick.',
              primaryLabel: 'Register Your Restaurant',
              primaryRoute: '/auth/register',
              secondaryLabel: 'See Pricing',
              secondaryRoute: '/pricing',
            ),
            const LandingFooter(),
          ],
        ),
      ),
    );
  }

  // -- Hero ----------------------------------------------------------------------

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
            child: Text('Simple. Fast. Transparent.',
                style: TextStyle(
                    fontSize: 12,
                    color: brand.navy,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'From sign-up to\nfirst order in minutes.',
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
              'Freequick is built for restaurant owners who want to focus on cooking — not managing technology.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: brand.muted, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  // -- Steps ---------------------------------------------------------------------

  Widget _buildSteps(BuildContext context, BrandColors brand,
      ColorScheme scheme, bool isWide, double h) {
    final steps = [
      _Step(
        number: '01',
        title: 'Create your account',
        description:
            'Register with your restaurant details. Takes under 2 minutes. No credit card required.',
        icon: Icons.person_add_rounded,
        color: brand.navy!,
      ),
      _Step(
        number: '02',
        title: 'Set up your profile',
        description:
            'Upload your logo, banner, and set your address. Your storefront goes live immediately.',
        icon: Icons.storefront_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      _Step(
        number: '03',
        title: 'Build your menu',
        description:
            'Add menus and items with photos, prices, and descriptions. Organise by category.',
        icon: Icons.restaurant_menu_rounded,
        color: brand.accentGreen!,
      ),
      _Step(
        number: '04',
        title: 'Receive orders',
        description:
            'Customers find you, place orders, and pay online. You see every order in real-time on your dashboard.',
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFD97706),
      ),
      _Step(
        number: '05',
        title: 'Get paid',
        description:
            'Revenue is settled to your registered bank account. You only pay a small commission per completed order.',
        icon: Icons.account_balance_rounded,
        color: const Color(0xFFEF4444),
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 80 : 48),
      child: Column(
        children: [
          LandingSectionLabel('THE PROCESS'),
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

  // -- Feature grid ---------------------------------------------------------------------------

  Widget _buildFeatureGrid(BuildContext context, BrandColors brand,
      ColorScheme scheme, bool isWide, double h) {
    final items = [
      _GridItem(
          Icons.bolt_rounded,
          'Real-time orders',
          'Every order appears on your dashboard instantly. No refresh needed.',
          brand.navy!),
      _GridItem(
          Icons.analytics_rounded,
          'Sales analytics',
          'See revenue, popular items, and order trends across 7 or 30 days.',
          const Color(0xFF8B5CF6)),
      _GridItem(
          Icons.image_rounded,
          'Custom branding',
          'Your logo, banner, and colours — your restaurant, your identity.',
          brand.accentGreen!),
      _GridItem(
          Icons.lock_rounded,
          'Secure payments',
          'All payments processed securely. You never handle card data.',
          const Color(0xFFD97706)),
      _GridItem(
          Icons.devices_rounded,
          'Works everywhere',
          'Dashboard runs on desktop, tablet, and mobile. Manage from anywhere.',
          const Color(0xFFEF4444)),
      _GridItem(
          Icons.support_agent_rounded,
          'Dedicated support',
          'Real people available to help you get set up and stay running.',
          const Color(0xFF0EA5E9)),
    ];

    return Container(
      color: scheme.surface,
      padding: EdgeInsets.symmetric(horizontal: h, vertical: isWide ? 80 : 48),
      child: Column(
        children: [
          LandingSectionLabel('WHAT YOU GET'),
          const SizedBox(height: 16),
          Text('Everything a restaurant needs.',
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

// -- Step row ----------------------------------------------------------------------

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

// -- Grid card ---------------------------------------------------------------------

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

// -- Data models -------------------------------------------------------------------

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
