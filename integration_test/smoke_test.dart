import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('smoke: app builds and home page renders', (tester) async {
    await tester.pumpWidget(buildTestApp());
    // Give UI 3 seconds to settle without pumpAndSettle to avoid hangs.
    await tester.pump(const Duration(seconds: 3));

    expect(find.text('Meet Beauty'), findsOneWidget);
  });
}
