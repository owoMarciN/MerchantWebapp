import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:user_app/l10n/app_localizations.dart';
import 'package:user_app/models/language.dart';

import 'package:provider/provider.dart';
import 'package:user_app/providers/locale_provider.dart';
import 'package:user_app/providers/menu_provider.dart';
import 'package:user_app/providers/local_stats_provider.dart';
import 'package:user_app/providers/global_stats_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/global/global.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:go_router/go_router.dart';

import 'package:user_app/auth/auth_screen.dart';
import 'package:dynamic_path_url_strategy/dynamic_path_url_strategy.dart';

import 'package:user_app/screens/landing_page_screen.dart';
import 'package:user_app/screens/splash_screen.dart';
import 'package:user_app/screens/dashboard_shell.dart';
import 'package:user_app/screens/overview_screen.dart';
import 'package:user_app/screens/orders_screen.dart';
import 'package:user_app/screens/menus_screen.dart';
import 'package:user_app/screens/analytics_screen.dart';
import 'package:user_app/screens/settings_screen.dart';
import 'package:user_app/screens/how_it_works_screen.dart';
import 'package:user_app/screens/pricing_screen.dart';

import 'package:user_app/screens/admin/dashboard_shell.dart';
import 'package:user_app/screens/admin/overview_screen.dart';
import 'package:user_app/screens/admin/requests_screen.dart';

import 'package:user_app/services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:web/web.dart' as web;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await FirebaseAppCheck.instance.activate(
    providerWeb:
        ReCaptchaV3Provider("6LdxDXYsAAAAAMUEjjSL0wbJUGB3uYPPX8mzZoec"),
  );

  sharedPreferences = await SharedPreferences.getInstance();

  injectGoogleMapsScript(LocationService.googleMapsApiKey);

  LocaleProvider localeProvider = LocaleProvider();
  await localeProvider.loadLocale();

  setPathUrlStrategy();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(create: (_) => LocalStatsProvider(currentUid ?? '')),
        ChangeNotifierProvider(create: (_) => GlobalStatsProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider(currentUid ?? '')),
      ],
      child: const AdminApp(),
    ),
  );
}

// ── Navigator keys ───────────────────────────────────────────────────────────
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _userShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'userShell');
final GlobalKey<NavigatorState> _adminShellKey =
    GlobalKey<NavigatorState>(debugLabel: 'adminShell');

// ── Admin role check ──────────────────────────────────────────────────────────
Future<String?> _adminRedirect(BuildContext context, GoRouterState state) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  // Not signed in at all
  if (uid == null) return '/auth/login';

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();

  final role = doc.data()?['role']?.toString() ?? '';

  // Not an admin — send to restaurant dashboard
  if (role != 'admin') return '/dashboard';

  // Signed in as admin — allow through
  return null;
}

// ── Router ────────────────────────────────────────────────────────────────────
final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: <RouteBase>[

    // ── Public ───────────────────────────────────────────────────────────────
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/',
      builder: (context, state) => const LandingPageScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/splash',
      builder: (context, state) => const MySplashScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/auth/:mode',
      builder: (context, state) {
        final mode = state.pathParameters['mode'] ?? 'login';
        return AuthScreen(initialShowLogin: mode == 'login');
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/how-it-works',
      builder: (_, __) => const HowItWorksScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/pricing',
      builder: (_, __) => const PricingScreen(),
    ),

    // ── Restaurant dashboard ──────────────────────────────────────────────────
    ShellRoute(
      navigatorKey: _userShellKey,
      builder: (context, state, child) => DashboardShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const OverviewScreen(),
        ),
        GoRoute(
          path: '/dashboard/orders',
          builder: (_, __) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/dashboard/menus',
          builder: (_, __) => const MenusScreen(),
        ),
        GoRoute(
          path: '/dashboard/analytics',
          builder: (_, __) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/dashboard/settings',
          builder: (_, __) => const SettingsScreen(),
        ),
      ],
    ),

    // ── Admin panel ───────────────────────────────────────────────────────────
    ShellRoute(
      navigatorKey: _adminShellKey,
      redirect: _adminRedirect,
      builder: (context, state, child) => AdminDashboardShell(child: child),
      routes: [
        GoRoute(
          path: '/admin/overview',
          builder: (_, __) => const AdminOverviewScreen(),
        ),
        GoRoute(
          path: '/admin/join-requests',
          builder: (_, __) => const RequestsScreen(),
        ),
      ],
    ),
  ],
);

// ── App ───────────────────────────────────────────────────────────────────────
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp.router(
      routerConfig: _router,
      title: 'Freequick',
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      locale: localeProvider.locale,
      supportedLocales: Language.languageList.map((lang) {
        return Locale(lang.code, lang.countryCode);
      }).toList(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
    );
  }
}

// ── Google Maps script injection ──────────────────────────────────────────────
void injectGoogleMapsScript(String apiKey) {
  const scriptId = 'google-maps-sdk';

  if (web.document.getElementById(scriptId) == null) {
    final script =
        web.document.createElement('script') as web.HTMLScriptElement;
    script.id = scriptId;
    script.src =
        'https://maps.googleapis.com/maps/api/js?key=$apiKey&libraries=places';
    script.async = true;
    script.defer = true;
    web.document.head?.appendChild(script);
  }
}