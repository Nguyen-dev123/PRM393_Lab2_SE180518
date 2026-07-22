import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prm393_lab2_se180518/main.dart' as app;
import 'test_helpers.dart';

void main() {
  patrolTest('Test Case 11 – Logout', ($) async {
    await app.main();
    await signInWithGoogleAndEnterApp($);

    // 1. Perform logout
    await $.tester.tap(find.text('Profile').first);
    await $.tester.pumpAndSettle();

    // Tap on Sign Out
    final signOutButton = find.text('Sign Out');
    if (signOutButton.evaluate().isEmpty) {
      await $.tester.tap(find.text('Account').first);
      await $.tester.pumpAndSettle();
    }

    await $.tester.tap(find.text('Sign Out'));
    await $.tester.pumpAndSettle();
    await slowDown($, seconds: 2);

    // 2. Verify redirection to the Login screen
    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
