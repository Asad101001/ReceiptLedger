// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:receipt_ledger_mobile/main.dart';

void main() {
  testWidgets('ReceiptLedgerApp renders navigation and main screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ReceiptLedgerApp());

    expect(find.text('Receipt Capture & OCR'), findsOneWidget);
    expect(find.text('Capture'), findsOneWidget);
    expect(find.text('Ledger'), findsOneWidget);
    expect(find.text('Review Queue'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
