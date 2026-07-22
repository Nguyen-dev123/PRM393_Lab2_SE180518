import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prm393_lab2_se180518/main.dart' as app;
import 'test_helpers.dart';
import 'package:flutter/material.dart';

void main() {
  patrolTest('Test Case 10 – Remote Config', ($) async {
    await app.main();
    await signInWithGoogleAndEnterApp($);

    // Navigate to Profile -> Settings to view remote config demo, or wherever it is displayed.
    await $.tester.tap(find.text('Profile').first);
    await $.tester.pumpAndSettle();
    
    // Tap Settings sub-tab
    await $.tester.tap(find.text('Settings'));
    await $.tester.pumpAndSettle();
    
    // 1. Retrieve Remote Config values (simulated by app behavior)
    // 2. Verify configuration values are displayed.
    // E.g., max_journals value or something similar
    expect(find.textContaining('Remote Config'), findsWidgets);
    
    await slowDown($, seconds: 2);
  });
}
