import 'package:flutter_test/flutter_test.dart';
import 'package:qrfri/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the QRfri home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    await store.load();

    await tester.pumpWidget(QrStudioApp(store: store));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('QRfri'), findsOneWidget);
    expect(find.text('Crear un código QR'), findsOneWidget);
  });
}
