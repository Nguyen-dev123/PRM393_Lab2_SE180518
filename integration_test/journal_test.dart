import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prm393_lab2_se180518/main.dart' as app;
import 'test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  patrolTest('Test Case 4 – Journals Navigation', ($) async {
    await app.main();
    await signInWithGoogleAndEnterApp($);

    // Do a search first to populate data
    final searchField = find.byType(TextField);
    await $(searchField).waitUntilVisible();
    await $.tester.enterText(searchField, 'Flutter');
    await $.tester.testTextInput.receiveAction(TextInputAction.search);
    await $.tester.pumpAndSettle();
    
    // Wait for search results
    await $(RegExp(r'results for')).waitUntilVisible(timeout: const Duration(seconds: 15));
    await slowDown($, seconds: 1);

    // 1. Navigate to the Journals tab.
    await $.tester.tap(find.text('Journal').first);
    await $.tester.pumpAndSettle();
    
    // 2. Verify journal statistics and journal list are displayed.
    await $(RegExp(r'Journals')).waitUntilVisible();
    expect(find.text('Publications'), findsWidgets); // Example stat text
    expect(find.byType(Card), findsWidgets); // Assuming journals are ListTiles or Cards
    
    await slowDown($, seconds: 2);
  });

  patrolTest('Test Case 5 – Journal Details', ($) async {
    await app.main();
    await signInWithGoogleAndEnterApp($);

    // Do a search first to populate data
    final searchField = find.byType(TextField);
    await $(searchField).waitUntilVisible();
    await $.tester.enterText(searchField, 'Flutter');
    await $.tester.testTextInput.receiveAction(TextInputAction.search);
    await $.tester.pumpAndSettle();
    
    // Wait for search results
    await $(RegExp(r'results for')).waitUntilVisible(timeout: const Duration(seconds: 15));
    await slowDown($, seconds: 1);

    // Navigate to Journal tab
    await $.tester.tap(find.text('Journal').first);
    await $.tester.pumpAndSettle();
    await $(RegExp(r'Journals')).waitUntilVisible();

    // 1. Open a journal from the journal list.
    final firstJournal = find.byType(Card).first;
    await $(firstJournal).tap();
    await $.tester.pumpAndSettle();
    
    // 2. Verify journal details are displayed correctly.
    // e.g. Total citations, publications...
    expect(find.textContaining('citations'), findsWidgets);
    expect(find.textContaining('publications'), findsWidgets);
    
    await slowDown($, seconds: 2);
  });
}

