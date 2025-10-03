import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart'; // generated via flutterfire CLI
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/firestore_provider.dart';
import 'providers/history_provider.dart';
import 'providers/tool_provider.dart';
import 'providers/theme_provider.dart';
import 'services/grok_service.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider(create: (_) => ToolProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => FirestoreProvider()),
        Provider(create: (_) => GrokService()),
        ChangeNotifierProxyProvider2<AuthProvider, FirestoreProvider, HistoryProvider>(
          create: (_) => HistoryProvider(
            context.read<AuthProvider>(),
            context.read<FirestoreProvider>(),
          ),
          update: (_, auth, firestore, previous) => HistoryProvider(
            auth,
            firestore,
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'SnapStoreAI',
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: themeProvider.themeMode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: SplashScreen.routeName,
            routes: {
              SplashScreen.routeName: (_) => const SplashScreen(),
              OnboardingScreen.routeName: (_) => const OnboardingScreen(),
              AuthScreen.routeName: (_) => const AuthScreen(),
              HomeScreen.routeName: (_) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}
