import 'package:buildcalc/app_settings.dart';
import 'package:buildcalc/main.dart';
import 'package:buildcalc/screens/settings_screen.dart';
import 'package:buildcalc/screens/splash_screen.dart';
import 'package:buildcalc/services/review_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BuildCalc app loads successfully', (tester) async {
    await tester.pumpWidget(const BuildCalcApp());
    await tester.pump();

    expect(find.text('BuildCalc'), findsWidgets);
  });

  testWidgets('splash screen does not render the app icon badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onSettingsChanged: (_) {})),
    );
    await tester.pump();

    expect(find.byIcon(Icons.calculate_rounded), findsNothing);
    expect(find.text('BuildCalc'), findsOneWidget);
  });

  testWidgets('settings screen hides the check-for-update action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          settings: const AppSettings(),
          onThemeChanged: (_) {},
          onLocaleChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Check for update'), findsNothing);
    expect(find.text('Theme'), findsOneWidget);
  });

  test('review service uses the Play Store review URL', () {
    final uri = ReviewService.playStoreReviewUri;

    expect(uri.host, 'play.google.com');
    expect(uri.queryParameters['id'], 'com.uksolutions.buildcalc');
    expect(uri.queryParameters.containsKey('showAllReviews'), isTrue);
  });
}
