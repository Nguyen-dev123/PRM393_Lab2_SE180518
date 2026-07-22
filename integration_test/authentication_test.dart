import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prm393_lab2_se180518/main.dart' as app;
import 'test_helpers.dart';

void main() {
  patrolTest('Test Case 1 – Google Sign-In', ($) async {
    await app.main();

    // 1. Launch the application
    // 2. Perform Google Sign-In
    await signInWithGoogleAndEnterApp($);

    // 3. Verify successful navigation to the Home screen
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Keywords'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
