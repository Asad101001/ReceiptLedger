import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_ledger_mobile/main.dart';

void main() {
  testWidgets('ReceiptLedgerApp renders navigation and main screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ReceiptLedgerApp());

    expect(find.text('ReceiptLedger'), findsWidgets);
    expect(find.text('CAPTURE'), findsOneWidget);
    expect(find.text('Capture'), findsOneWidget);
    expect(find.text('Ledger'), findsOneWidget);
    expect(find.text('Review'), findsWidgets);
    expect(find.text('Single Receipt'), findsOneWidget);
  });
}
