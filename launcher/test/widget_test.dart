import 'package:flutter_test/flutter_test.dart';
import 'package:olderos_launcher/main.dart';

void main() {
  testWidgets('OlderOS app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OlderOSApp());

    // Verify that the greeting is displayed.
    expect(find.textContaining('Buongiorno'), findsOneWidget);

    // Verify that app cards are displayed.
    expect(find.text('INTERNET'), findsOneWidget);
    expect(find.text('POSTA'), findsOneWidget);
    expect(find.text('FOTO'), findsOneWidget);
  });
}
