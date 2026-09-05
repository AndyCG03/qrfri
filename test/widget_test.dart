import 'package:flutter_test/flutter_test.dart';
import 'package:qrfri/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the QRfri home screen', (tester) async {
    // The launch gate shows the tutorial on a first run. This test targets
    // the home shell, so model a returning user while keeping the production
    // first-run behavior intact.
    SharedPreferences.setMockInitialValues({
      'seen_tutorial': true,
      'languageCode': 'es',
    });
    final store = LocalStore(await SharedPreferences.getInstance());
    await store.load();

    await tester.pumpWidget(QrStudioApp(store: store));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('QRfri'), findsOneWidget);
    expect(find.text('Crear un código QR'), findsOneWidget);
  });
}
