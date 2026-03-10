import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:user_app/extensions/responsive_ext.dart';
import 'package:user_app/widgets/language_button.dart';
import 'package:user_app/extensions/context_translate_ext.dart';

// -- CTA Block ---------------------------------------------------------------------
// Usage:
//   LandingCta(
//     title: 'Ready to grow?',
//     subtitle: 'Join restaurants already on Freequick.',
//     primaryLabel: 'Register Your Restaurant',
//     primaryRoute: '/auth/register',
//     secondaryLabel: 'See Pricing',   // optional
//     secondaryRoute: '/pricing',       // optional
//   )
class LandingCta extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String primaryLabel;
  final String primaryRoute;
  final String? secondaryLabel;
  final String? secondaryRoute;

  const LandingCta({
    super.key,
    required this.title,
    this.subtitle,
    required this.primaryLabel,
    required this.primaryRoute,
    this.secondaryLabel,
    this.secondaryRoute,
  });

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;
    final isWide = context.isWide;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 32, vertical: isWide ? 72 : 48),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brand.navy!, brand.navyDark ?? brand.navy!]),
      ),
      child: Column(
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: isWide ? 36 : 26,
                  color: Colors.white,
                  fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, color: Colors.white.withValues(alpha: 0.7))),
          ],
          const SizedBox(height: 36),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              LandingPrimaryButton(
                  label: primaryLabel,
                  onTap: () =>
                      Router.neglect(context, () => context.go(primaryRoute)),
                  white: true,
                  large: true),
              if (secondaryLabel != null && secondaryRoute != null)
                LandingOutlineButton(
                    label: secondaryLabel!,
                    onTap: () => Router.neglect(
                        context, () => context.go(secondaryRoute!)),
                    white: true,
                    large: true),
            ],
          ),
        ],
      ),
    );
  }
}

// -- Nav ---------------------------------------------------------------------------

class LandingNav extends StatelessWidget {
  final String activeRoute;

  const LandingNav({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final isWide = context.isWide;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 60 : 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: Row(
        children: [
          LandingLogo(),
          const Spacer(),
          if (isWide) ...[
            LandingNavLink(
              context.l10n.how_it_works,
              active: activeRoute == '/how-it-works',
              onTap: () =>
                  Router.neglect(context, () => context.go('/how-it-works')),
            ),
            const SizedBox(width: 32),
            LandingNavLink(
              context.l10n.pricing,
              active: activeRoute == '/pricing',
              onTap: () =>
                  Router.neglect(context, () => context.go('/pricing')),
            ),
            const SizedBox(width: 40),
          ],
          LandingOutlineButton(
              label: context.l10n.log_in,
              onTap: () =>
                  Router.neglect(context, () => context.go('/auth/login'))),
          const SizedBox(width: 12),
          LandingPrimaryButton(
              label: context.l10n.get_started,
              onTap: () =>
                  Router.neglect(context, () => context.go('/auth/register'))),
          const SizedBox(width: 16),
          LanguageButton(brandColors: brand, colorScheme: scheme)
        ],
      ),
    );
  }
}

// -- Footer ------------------------------------------------------------------------

class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: scheme.outline))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          LandingLogo(),
          Text('© 2026 Freequick',
              style: TextStyle(fontSize: 13, color: brand.muted)),
        ],
      ),
    );
  }
}

// -- Logo --------------------------------------------------------------------------

class LandingLogo extends StatelessWidget {
  const LandingLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;

    return GestureDetector(
      onTap: () => Router.neglect(context, () => context.go('/')),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: brand.navy, borderRadius: BorderRadius.circular(6)),
            child:
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text('Freequick',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}

// -- Nav link ----------------------------------------------------------------------

class LandingNavLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool active;

  const LandingNavLink(this.label,
      {super.key, this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;

    return GestureDetector(
      onTap: onTap,
      child: Text(label,
          style: TextStyle(
              color: active
                  ? Theme.of(context).colorScheme.onSurface
                  : brand.muted,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
    );
  }
}

// -- Primary button -----------------------------------------------------------------------------

class LandingPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool large;
  final bool white;

  const LandingPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.large = false,
    this.white = false,
  });

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: white ? Colors.white : brand.navy,
        foregroundColor: white ? brand.navy : Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(
            horizontal: large ? 28 : 16, vertical: large ? 18 : 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

// -- Outline button -----------------------------------------------------------------------------

class LandingOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool large;
  final bool white;

  const LandingOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.large = false,
    this.white = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: white ? Colors.white : scheme.onSurface,
        side: BorderSide(
            color:
                white ? Colors.white.withValues(alpha: 0.4) : scheme.outline),
        padding: EdgeInsets.symmetric(
            horizontal: large ? 28 : 16, vertical: large ? 18 : 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}

// -- Section label ------------------------------------------------------------------------------

class LandingSectionLabel extends StatelessWidget {
  final String text;
  const LandingSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final brand = Theme.of(context).extension<BrandColors>()!;
    return Text(text,
        style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: brand.muted,
            letterSpacing: 1.8));
  }
}
