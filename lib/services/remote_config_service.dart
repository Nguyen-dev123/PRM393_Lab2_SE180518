import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

/// Wraps Firebase Remote Config.
/// Default values are used until the remote fetch succeeds.
///
/// Config keys (set these in the Firebase Console):
///   welcome_message   — String  — shown in Profile settings
///   app_theme_color   — String  — "indigo" | "blue" | "teal" | etc.
///   max_journals      — int     — max journals shown in analytics (default 10)
///   max_keywords      — int     — max keywords extracted from titles (default 20)
class RemoteConfigService {
  static final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    await _rc.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      // Use a short interval during development; set to hours in production
      minimumFetchInterval: const Duration(seconds: 0), // dev mode: fetch immediately
    ));

    // Default values — applied immediately before any remote fetch
    await _rc.setDefaults(const {
      'welcome_message': 'Welcome to Journal Trend Analyzer',
      'app_theme_color': 'indigo',
      'max_journals': 10,
      'max_keywords': 20,
    });

    await _rc.fetchAndActivate();
  }

  // ── Getters ─────────────────────────────────────────────────

  static String get welcomeMessage => _rc.getString('welcome_message');

  static String get themeColorName => _rc.getString('app_theme_color').toLowerCase();

  static int get maxJournals => _rc.getInt('max_journals');

  static int get maxKeywords => _rc.getInt('max_keywords');

  /// Returns a [MaterialColor] based on the remote config value.
  static MaterialColor get themeColor {
    switch (themeColorName) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.indigo;
    }
  }
}
