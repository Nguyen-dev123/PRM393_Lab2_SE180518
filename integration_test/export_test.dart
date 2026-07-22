import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prm393_lab2_se180518/main.dart' as app;
import 'test_helpers.dart';
import 'package:flutter/material.dart';

void main() {
  patrolTest('Test Case 9 – PDF Export', ($) async {
    await app.main();
    await signInWithGoogleAndEnterApp($);

    // Search for something so that there is data to export
    final searchField = find.byType(TextField);
    await $(searchField).waitUntilVisible();
    await $.tester.enterText(searchField, 'Flutter');
    await $.tester.testTextInput.receiveAction(TextInputAction.search);
    await $.tester.pumpAndSettle();
    
    // Wait for search results
    await $(RegExp(r'results for')).waitUntilVisible(timeout: const Duration(seconds: 15));
    await slowDown($, seconds: 1);

    // Navigate to Profile tab
    await $.tester.tap(find.text('Profile').first);
    await $.tester.pumpAndSettle();
    
    // Tap Settings sub-tab
    await $.tester.tap(find.text('Settings'));
    await $.tester.pumpAndSettle();
    
    // 1. Generate a PDF report (and 2. Upload to Firebase Storage)
    final exportButton = find.text('Export PDF Report');
    expect(exportButton, findsOneWidget);
    await $.tester.tap(exportButton);
    
    // 3. Verify successful upload
    // Typically a snackbar or success dialog will appear.
    // We wait up to 15 seconds for upload to complete
    await $(RegExp(r'(Upload successful|Success|successfully|PDF Uploaded!)')).waitUntilVisible(timeout: const Duration(seconds: 15));
    
    await slowDown($, seconds: 2);
  });
}
