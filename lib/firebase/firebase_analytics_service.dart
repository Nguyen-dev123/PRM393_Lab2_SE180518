import 'package:firebase_analytics/firebase_analytics.dart';

/// Centralises all Firebase Analytics event logging.
/// Call these methods from ViewModels and Services — never from UI widgets directly.
class FirebaseAnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // NavigatorObserver — pass to MaterialApp.navigatorObservers for automatic
  // screen tracking.
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Auth events ─────────────────────────────────────────────

  /// Called after a successful Google Sign-In.
  static Future<void> logLogin() =>
      _analytics.logLogin(loginMethod: 'google');

  /// Called after the user signs out.
  static Future<void> logLogout() =>
      _analytics.logEvent(name: 'logout');

  // ── Search events ────────────────────────────────────────────

  /// Called when the user executes a topic search.
  static Future<void> logSearchTopic(String keyword) =>
      _analytics.logEvent(
        name: 'search_topic',
        parameters: {'keyword': keyword},
      );

  // ── View events ──────────────────────────────────────────────

  /// Called when a Publication Detail screen is opened.
  static Future<void> logViewPublication(String title, int year) =>
      _analytics.logEvent(
        name: 'view_publication',
        parameters: {
          'publication_title': title,
          'publication_year': year,
        },
      );

  /// Called when a Journal Detail screen is opened.
  static Future<void> logViewJournal(String journalName) =>
      _analytics.logEvent(
        name: 'view_journal',
        parameters: {'journal_name': journalName},
      );

  /// Called when a Keyword Detail screen is opened.
  static Future<void> logViewKeyword(String keyword) =>
      _analytics.logEvent(
        name: 'view_keyword',
        parameters: {'keyword': keyword},
      );

  // ── Export events ────────────────────────────────────────────

  /// Called when a PDF report is exported and uploaded to Firebase Storage.
  static Future<void> logExportPdf(String topic) =>
      _analytics.logEvent(
        name: 'export_pdf',
        parameters: {'topic': topic},
      );
}
