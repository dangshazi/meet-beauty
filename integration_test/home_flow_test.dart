import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('首页流程', () {
    testWidgets('首页正确展示标题、副标题和功能亮点', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Meet Beauty'), findsOneWidget);
      expect(find.text('AI Makeup Coach'), findsOneWidget);
      expect(find.text('Face Analysis'), findsOneWidget);
      expect(find.text('AR Tutorial'), findsOneWidget);
      expect(find.text('Smart Scoring'), findsOneWidget);
      expect(find.text('Start Learning'), findsOneWidget);
    });

    testWidgets('点击 Start Learning 导航到面部分析页', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.text('Start Learning'));
      // Wait for navigation animation to complete.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Face Analysis'), findsOneWidget);
      expect(find.text('Your Features'), findsOneWidget);
    });

    testWidgets('首页主要功能区域全部可见', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      // Core content visible on screen.
      expect(find.text('Meet Beauty'), findsOneWidget);
      expect(find.text('Start Learning'), findsOneWidget);
    });
  });
}
