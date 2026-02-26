import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:user_app/l10n/app_localizations.dart';
import 'package:user_app/models/language.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/assistant_methods/address_changer.dart';
import 'package:user_app/assistant_methods/locale_provider.dart';

import 'package:user_app/global/global.dart';
import 'package:user_app/screens/landing_page_screen.dart';
import 'package:user_app/extensions/brand_color_ext.dart';
import 'package:go_router/go_router.dart';

import 'package:user_app/screens/dashboard_shell.dart';
import 'package:user_app/authentication/auth_screen.dart';
import 'package:user_app/screens/splash_screen.dart';
import 'package:dynamic_path_url_strategy/dynamic_path_url_strategy.dart';

import 'package:user_app/screens/overview_screen.dart';
import 'package:user_app/screens/orders_screen.dart';
import 'package:user_app/screens/menus_screen.dart';
import 'package:user_app/screens/analytics_screen.dart';
import 'package:user_app/screens/settings_screen.dart';

import 'package:user_app/services/location_service.dart';

import 'package:web/web.dart' as web;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    providerWeb: ReCaptchaV3Provider("6LdxDXYsAAAAAMUEjjSL0wbJUGB3uYPPX8mzZoec"), 
  );

  // Initialize SharedPreferences
  sharedPreferences = await SharedPreferences.getInstance();

  // Loading the API KEY to the index.html
  injectGoogleMapsScript(LocationService.googleMapsApiKey);

  // Load Saved Locale
  LocaleProvider localeProvider = LocaleProvider();
  await localeProvider.loadLocale();

  AddressChanger addressChanger = AddressChanger();
  await addressChanger.loadSavedAddress();

  setPathUrlStrategy();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: addressChanger),
      ],
      child: const AdminApp()
    ),
  );
}

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const LandingPageScreen()),
    GoRoute(
      path: '/splash',
      builder: (context, state) => const MySplashScreen(),
    ),
    GoRoute(path: '/auth/:mode', builder: (context, state) { 
        final mode = state.pathParameters['mode'] ?? 'login';
        return AuthScreen(initialShowLogin: mode == 'login');
      },
    ),
    ShellRoute(
      builder: (context, state, child) => DashboardShell(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const OverviewScreen()),
        GoRoute(path: '/dashboard/orders', builder: (_, __) => const OrdersScreen()),
        GoRoute(path: '/dashboard/menus', builder: (_, __) => const MenusScreen()),
        GoRoute(path: '/dashboard/analytics', builder: (_, __) => const AnalyticsScreen()),
        GoRoute(path: '/dashboard/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);

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

      // Autmatically fetching the languages list from language_model.dart
      supportedLocales: Language.languageList.map((lang) {
        return Locale(lang.code, lang.countryCode);
      }).toList(),

      localizationsDelegates: const[
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

void injectGoogleMapsScript(String apiKey) {
  const scriptId = 'google-maps-sdk';
  
  if (web.document.getElementById(scriptId) == null) {
    final script = web.document.createElement('script') as web.HTMLScriptElement;
    script.id = scriptId;
    script.src = "https://maps.googleapis.com/maps/api/js?key=$apiKey&libraries=places";
    script.async = true;
    script.defer = true;
    
    web.document.head?.appendChild(script);
  }
}