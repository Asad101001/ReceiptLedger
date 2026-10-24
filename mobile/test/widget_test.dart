import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_ledger_mobile/main.dart';
import 'package:receipt_ledger_mobile/screens/auth_screen.dart';
import 'package:receipt_ledger_mobile/screens/splash_screen.dart';

void main() {
  testWidgets('ReceiptLedgerApp renders navigation and main screen without splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ReceiptLedgerApp(showSplash: false));

    expect(find.text('ReceiptLedger'), findsWidgets);
    expect(find.text('CAPTURE'), findsOneWidget);
    expect(find.text('Capture'), findsOneWidget);
    expect(find.text('Ledger'), findsOneWidget);
    expect(find.text('Review'), findsWidgets);
    expect(find.text('Single Receipt'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ReceiptLedgerApp renders SplashScreen with brand mark and ticker', (WidgetTester tester) async {
    await tester.pumpWidget(const ReceiptLedgerApp(showSplash: true));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('ReceiptLedger'), findsOneWidget);
    expect(find.text('Tap to Continue →'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ReceiptLedgerApp renders AuthScreen with tabs and demo filler', (WidgetTester tester) async {
    await tester.pumpWidget(const ReceiptLedgerApp(
      showSplash: false,
      homeOverride: AuthScreen(),
    ));

    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('1-Click Demo Credentials'), findsOneWidget);
    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
