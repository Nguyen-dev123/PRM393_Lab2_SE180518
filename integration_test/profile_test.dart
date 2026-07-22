import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:prm393_lab2_se180518/main.dart' as app;
import 'test_helpers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  patrolTest('Test Case 8 – Profile Navigation', ($) async {
    await app.main();
    await signInWithGoogleAndEnterApp($);

    // 1. Navigate to the Profile tab.
    await $.tester.tap(find.text('Profile').first);
    await $.tester.pumpAndSettle();
    
    // 2. Verify user profile information is displayed.
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty) {
      expect(find.textContaining(currentUser.displayName!), findsWidgets);
    }
    if (currentUser?.email != null && currentUser!.email!.isNotEmpty) {
      expect(find.textContaining(currentUser.email!), findsWidgets);
    }
    expect(find.text('Sign Out'), findsWidgets);
    
    await slowDown($, seconds: 2);
  });
}
