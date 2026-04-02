import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_app.dart';

// Give navigation/rebuild time without relying on pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 500));
}

/// Navigate from home → analysis → recommendation → tutorial.
Future<void> _navigateToTutorial(WidgetTester tester) async {
  await tester.tap(find.text('Start Learning'));
  await _settle(tester);

  // Analysis page: mock auto-detects face; Capture & Analyze is enabled.
  await tester.tap(find.text('Capture & Analyze'));
  await _settle(tester);

  // Analysis complete; navigate to recommendations.
  await tester.tap(find.text('Get Recommendations'));
  await _settle(tester);

  // Recommendation page: Start Learning enters tutorial.
  await tester.tap(find.text('Start Learning'));
  await _settle(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('教学流程', () {
    testWidgets('进入教学页显示第一步内容', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      await _navigateToTutorial(tester);

      expect(find.text('Apply Lip Color'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('完成三步教学后进入结果页并显示分数', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      await _navigateToTutorial(tester);

      // Step 1 visible
      expect(find.text('Apply Lip Color'), findsOneWidget);
      expect(find.text('下一步'), findsOneWidget);

      // Step 1 → 2
      await tester.tap(find.text('下一步'));
      await _settle(tester);
      expect(find.text('Add Blush - Left Cheek'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);

      // Back to step 1
      await tester.tap(find.text('上一步'));
      await _settle(tester);
      expect(find.text('Apply Lip Color'), findsOneWidget);

      // Forward again to step 2
      await tester.tap(find.text('下一步'));
      await _settle(tester);

      // Step 2 → 3
      await tester.tap(find.text('下一步'));
      await _settle(tester);
      expect(find.text('Add Blush - Right Cheek'), findsOneWidget);
      expect(find.text('完成教学'), findsOneWidget);
      expect(find.text('3 / 3'), findsOneWidget);

      // Complete tutorial
      await tester.tap(find.text('完成教学'));
      await _settle(tester);

      // Result page（与 result_page 中文文案一致）
      expect(find.text('满分 100'), findsOneWidget);
      expect(find.text('再练一次'), findsOneWidget);
      expect(find.text('返回首页'), findsOneWidget);
    });

    testWidgets('步骤进度显示 1 / 3', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      await _navigateToTutorial(tester);

      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('结果页点击返回首页', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      await _navigateToTutorial(tester);

      await tester.tap(find.text('下一步'));
      await _settle(tester);
      await tester.tap(find.text('下一步'));
      await _settle(tester);
      await tester.tap(find.text('完成教学'));
      await _settle(tester);

      await tester.tap(find.text('返回首页'));
      await _settle(tester);

      expect(find.text('Meet Beauty'), findsOneWidget);
    });

    testWidgets('结果页点击再练一次重新进入教学', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      await _navigateToTutorial(tester);

      await tester.tap(find.text('下一步'));
      await _settle(tester);
      await tester.tap(find.text('下一步'));
      await _settle(tester);
      await tester.tap(find.text('完成教学'));
      await _settle(tester);

      await tester.tap(find.text('再练一次'));
      await _settle(tester);

      expect(find.text('Apply Lip Color'), findsOneWidget);
    });
  });
}
