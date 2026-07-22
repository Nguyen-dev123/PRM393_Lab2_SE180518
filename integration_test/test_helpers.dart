// Shared helpers cho tất cả patrol tests
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:patrol/patrol.dart';

/// Delay realtime
Future<void> slowDown(PatrolIntegrationTester $, {int seconds = 2}) async {
  await $.tester.runAsync(() async {
    await Future.delayed(Duration(seconds: seconds));
  });
}

/// Đăng nhập bằng Google qua Patrol UI Automator
Future<void> signInWithGoogleAndEnterApp(PatrolIntegrationTester $) async {
  // Đảm bảo user đã đăng xuất trước khi test login
  final existingUser = FirebaseAuth.instance.currentUser;
  if (existingUser != null) {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
    await $.tester.pumpAndSettle();
  }

  // Chờ hiển thị nút "Sign in with Google"
  await $('Sign in with Google').waitUntilVisible();
  await slowDown($, seconds: 1);

  // Bấm nút Sign in with Google
  await $('Sign in with Google').tap();

  // Đợi popup native của Google hiện lên, tăng thời gian chờ
  try {
    // Thử đợi account email
    await $.native.waitUntilVisible(Selector(textContains: '@gmail.com'), timeout: const Duration(seconds: 15));
    await $.native.tap(Selector(textContains: '@gmail.com'));
  } catch (e) {
    try {
      // Dự phòng: tap bằng resourceId của Android
      await $.native.tap(Selector(resourceId: 'com.google.android.gms:id/account_name'));
    } catch (e2) {
      // Bỏ qua nếu không tìm thấy (có thể login tự động xảy ra)
      print('Could not find Google account selector, maybe already logged in automatically?');
    }
  }

  // Chờ MainShell load xong
  await $('Home').waitUntilVisible(timeout: const Duration(seconds: 15));
  await slowDown($, seconds: 2);
}

