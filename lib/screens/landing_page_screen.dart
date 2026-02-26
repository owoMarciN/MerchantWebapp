import 'package:flutter/material.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:go_router/go_router.dart';

class LandingPageScreen extends StatelessWidget {
  const LandingPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brandColors = Theme.of(context).extension<BrandColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildNav(context, brandColors, colorScheme),
            _buildHero(context, brandColors, colorScheme),
            _buildLogoBanner(context, brandColors),
            _buildFeatures(context, brandColors, colorScheme),
            _buildCta(context, brandColors, colorScheme),
            _buildFooter(context, brandColors),
          ],
        ),
      ),
    );
  }

  Widget _buildNav(BuildContext context, BrandColors brand, ColorScheme scheme) {
    final bool isWide = MediaQuery.of(context).size.width > 700;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: Row(
        children: [
          _Logo(brand: brand),
          const Spacer(),
          if (isWide) ...[
            _NavLink('How it Works', brand: brand),
            const SizedBox(width: 32),
            _NavLink('Pricing', brand: brand),
            const SizedBox(width: 40),
          ],
          _OutlineButton(
            label: 'Login',
            brand: brand,
            scheme: scheme,
            onTap: () => context.go('/auth/login')
          ),
          const SizedBox(width: 12),
          _PrimaryButton(
            label: 'Get Started',
            brand: brand,
            onTap: () => context.go('/auth/register')
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, BrandColors brand, ColorScheme scheme) {
    final bool isWide = MediaQuery.of(context).size.width > 700;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 24, vertical: isWide ? 120 : 72),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: brand.navy?.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: brand.navy?.withValues(alpha: 0.4) ?? Colors.transparent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(brand.accentGreen ?? Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Now live in Wrocław',
                  style: TextStyle(fontSize: 12, color: brand.accentGreen, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Text(
              'Put your restaurant on\nWrocław\'s screens.',
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
              'Manage your menu, upload custom banners, and track orders in real-time.',
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
              _PrimaryButton(
                label: 'Register Your Restaurant',
                brand: brand, 
                onTap: () {}, 
                large: true
              ),
              _OutlineButton(
                label: 'See How it Works', 
                brand: brand, 
                scheme: scheme, 
                onTap: () {}, 
              large: true),
            ],
          ),
          const SizedBox(height: 80),
          _buildDashboardPreview(brand, scheme),
        ],
      ),
    );
  }

  Widget _buildDashboardPreview(BrandColors brand, ColorScheme scheme) {
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
            Row(
              children: [
                _dot(Colors.redAccent), const SizedBox(width: 6),
                _dot(Colors.orangeAccent), const SizedBox(width: 6),
                _dot(Colors.greenAccent),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _previewStat('Orders Today', '148', brand.accentGreen!, brand)),
                const SizedBox(width: 12),
                Expanded(child: _previewStat('Active Menus', '12', brand.navy!, brand)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color color) => Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _previewStat(String label, String value, Color color, BrandColors brand) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: brand.muted)),
        ],
      ),
    );
  }

  Widget _buildLogoBanner(BuildContext context, BrandColors brand) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: Theme.of(context).colorScheme.outline))),
      child: Column(
        children: [
          Text('TRUSTED BY RESTAURANTS', style: TextStyle(fontSize: 10, color: brand.muted, letterSpacing: 2)),
          const SizedBox(height: 24),
          // ... Rest of your logo list
        ],
      ),
    );
  }

  Widget _buildFeatures(BuildContext context, BrandColors brand, ColorScheme scheme) {
    final bool isWide = MediaQuery.of(context).size.width > 700;
    final features = [
      _Feature(Icons.restaurant_menu_rounded, 'Digital Menu', 'Your menu goes live instantly.', brand.navy!),
      _Feature(Icons.image_rounded, 'Custom Banners', 'Full creative control.', const Color(0xFF8B5CF6)),
      _Feature(Icons.bar_chart_rounded, 'Sales Analytics', 'Track peak hours.', brand.accentGreen!),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 24, vertical: 100),
      child: Column(
        children: [
          Text('FEATURES', style: TextStyle(color: brand.muted, letterSpacing: 2)),
          const SizedBox(height: 60),
          isWide 
            ? Row(children: features.map((f) => Expanded(child: _FeatureCard(feature: f, brand: brand, scheme: scheme))).toList())
            : Column(children: features.map((f) => _FeatureCard(feature: f, brand: brand, scheme: scheme)).toList()),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context, BrandColors brand, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [brand.navy!, brand.navyDark!]),
      ),
      child: Column(
        children: [
          const Text('Ready to grow?', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: brand.navyDark),
            child: const Text(
              'Register Now',
              style: TextStyle(
                fontWeight: FontWeight.bold
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, BrandColors brand) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Logo(brand: brand),
          Text('© 2026 Freequick', style: TextStyle(color: brand.muted)),
        ],
      ),
    );
  }
}

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
  const _FeatureCard({required this.feature, required this.brand, required this.scheme});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(feature.icon, color: feature.color),
              const SizedBox(width: 16),
              Text(feature.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ]
          ),
          const SizedBox(height: 8),
          Text(feature.desc, style: TextStyle(color: brand.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final BrandColors brand;
  const _Logo({required this.brand});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: brand.navy, borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        const Text('Freequick', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final BrandColors brand;
  const _NavLink(this.label, {required this.brand});
  @override
  Widget build(BuildContext context) => Text(label, style: TextStyle(color: brand.muted, fontWeight: FontWeight.w500));
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final BrandColors brand;
  final bool large;
  const _PrimaryButton({required this.label, required this.onTap, required this.brand, this.large = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: brand.navy,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: large ? 32 : 16, vertical: large ? 20 : 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final BrandColors brand;
  final ColorScheme scheme;
  final bool large;
  const _OutlineButton({required this.label, required this.onTap, required this.brand, required this.scheme, this.large = false});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: brand.accentGreen,
        side: BorderSide(color: scheme.outline),
        padding: EdgeInsets.symmetric(horizontal: large ? 32 : 16, vertical: large ? 20 : 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}