import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prm393_lab2_se180518/main.dart' as app;
import 'test_helpers.dart';

void main() {
  patrolTest('Test Case 2 – Topic Search', ($) async {
    await app.main();
    await signInWithGoogleAndEnterApp($);

    // 1. Enter a research topic.
    final searchField = find.byType(TextField);
    await $(searchField).waitUntilVisible(timeout: const Duration(seconds: 15));
    expect(searchField, findsOneWidget);
    await $.tester.enterText(searchField, 'Artificial Intelligence');
    
    // 2. Execute search.
    await $.tester.testTextInput.receiveAction(TextInputAction.search);
    await $.tester.pumpAndSettle();
    
    // 3. Verify publication results are displayed.
    await $(RegExp(r'results for')).waitUntilVisible(timeout: const Duration(seconds: 15));
    expect(find.byType(Card), findsWidgets);
    await slowDown($, seconds: 2);
  });

  patrolTest('Test Case 3 – Publication Details', ($) async {
    await app.main();
    await signInWithGoogleAndEnterApp($);

    // Search first
    final searchField = find.byType(TextField);
    await $(searchField).waitUntilVisible();
    await $.tester.enterText(searchField, 'Flutter development');
    await $.tester.testTextInput.receiveAction(TextInputAction.search);
    await $.tester.pumpAndSettle();
    
    await $(RegExp(r'results for')).waitUntilVisible(timeout: const Duration(seconds: 15));

    // 1. Open a publication from the search results.
    final firstPublication = find.byType(Card).first;
    await $(firstPublication).tap();
    await $.tester.pumpAndSettle();
    
    // 2. Verify publication information is displayed correctly.
    // At least some details should be visible, e.g., Title, Authors, Citation count
    expect(find.textContaining('DOI'), findsWidgets);
    expect(find.textContaining('Authors'), findsOneWidget);
    expect(find.textContaining('Citations'), findsOneWidget);
    
    await slowDown($, seconds: 2);
  });
}
