import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prm393_lab2_se180518/main.dart' as app;
import 'test_helpers.dart';
import 'package:flutter/material.dart';

void main() {
  patrolTest('Test Case 7 – Keyword Details', ($) async {
    await app.main();
    await signInWithGoogleAndEnterApp($);

    // 0. Search first to populate data
    final searchField = find.byType(TextField);
    await $(searchField).waitUntilVisible();
    await $.tester.enterText(searchField, 'Flutter');
    await $.tester.testTextInput.receiveAction(TextInputAction.search);
    await $.tester.pumpAndSettle();

    // Wait for search results
    await $(RegExp(r'results for')).waitUntilVisible(timeout: const Duration(seconds: 15));
    await slowDown($, seconds: 1);

    // Navigate to Keywords tab
    await $.tester.tap(find.text('Keywords').first);
    await $.tester.pumpAndSettle();

    // Navigate into Keywords sub-tab (Icons.tag icon)
    await $.tester.tap(find.byIcon(Icons.tag).first);
    await $.tester.pumpAndSettle();
    await $(find.text('Keyword Frequency')).waitUntilVisible(timeout: const Duration(seconds: 40));

    // 1. Open a keyword from the keyword list.
    final firstKeyword = find.byIcon(Icons.chevron_right).first;
    await $(firstKeyword).tap();
    await $.tester.pumpAndSettle();

    // 2. Verify keyword analysis information is displayed.
    expect(find.textContaining('Trend'), findsWidgets);
    expect(find.textContaining('Peak year'), findsWidgets);

    await slowDown($, seconds: 2);
  });
}
