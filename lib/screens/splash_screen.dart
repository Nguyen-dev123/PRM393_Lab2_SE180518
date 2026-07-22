import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/config_provider.dart';

/// Shown briefly by _AuthGate while waiting for the first auth state event.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appTheme[700],
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.analytics, size: 58, color: context.appTheme),
            ),
            const SizedBox(height: 24),
            const Text(
              'Journal Trend Analyzer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Powered by OpenAlex',
              style: TextStyle(color: context.appTheme[200], fontSize: 13),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                value: 0.5, // Fixed value prevents infinite animation, allowing pumpAndSettle to work in tests
                backgroundColor: context.appTheme[500],
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
