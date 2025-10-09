import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'admin/jsontooluploader.dart';
import 'firebase_options.dart'; // generated via flutterfire CLI
import 'l10n/app_localizations.dart';
import 'providers/api_key_provider.dart';
import 'providers/history_provider.dart';
import 'providers/tool_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/favorite_tools_provider.dart';
import 'theme/app_theme.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiKeyProvider()),
        ChangeNotifierProvider(create: (_) => ToolProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteToolsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SnapStoreAI',
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.themeMode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: SplashScreen.routeName,
            routes: {
              SplashScreen.routeName: (_) => const SplashScreen(),
              OnboardingScreen.routeName: (_) => const OnboardingScreen(),
              HomeScreen.routeName: (_) => const HomeScreen(),
              '/admin/uploader': (_) => const JsonToolUploaderScreen(),
            },
          );
        },
      ),
    );
  }
}
