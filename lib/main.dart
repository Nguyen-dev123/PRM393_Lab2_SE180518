import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'state/search_provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/bookmark_viewmodel.dart';
import 'services/remote_config_service.dart';
import 'services/push_notification_service.dart';
import 'firebase/firebase_analytics_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'state/config_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  try {
    await RemoteConfigService.initialize();
  } catch (e) {
    debugPrint('Remote Config Init Error: $e');
  }

  try {
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint('FCM Init Error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ConfigProvider()),
        ChangeNotifierProxyProvider<AuthViewModel, BookmarkViewModel?>(
          create: (_) => null,
          update: (_, auth, prev) {
            final uid = auth.user?.uid;
            if (uid == null) return null;
            if (prev != null) return prev;
            return BookmarkViewModel(uid);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.watch<ConfigProvider>().themeColor;
    return MaterialApp(
      title: 'Journal Trend Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: themeColor),
        useMaterial3: true,
      ),
      // Root route: listens to Firebase auth state and routes accordingly.
      // This ensures sign-out from any screen automatically shows LoginScreen.
      home: const _AuthGate(),
      navigatorObservers: [FirebaseAnalyticsService.observer],
    );
  }
}

/// Listens to Firebase auth state and routes between LoginScreen and MainShell.
/// No manual Navigator.push needed — just sign in/out and the gate reacts.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While waiting for the first auth state event, show a splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}
