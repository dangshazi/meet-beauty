import 'package:flutter_test/flutter_test.dart';
import 'package:meet_beauty/app/app.dart';

void main() {
  testWidgets('App loads and displays home page', (WidgetTester tester) async {
    await tester.pumpWidget(const MeetBeautyApp());

    // Verify app title is displayed
    expect(find.text('Meet Beauty'), findsOneWidget);
  });
}
