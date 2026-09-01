import 'package:flutter_test/flutter_test.dart';

import 'package:ai_work_planner/main.dart';

void main() {
  testWidgets('AI Work Planner starts successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AIWorkPlannerApp());

    expect(find.text('AI Work Planner'), findsOneWidget);
    expect(find.text('Boost Your Productivity'), findsOneWidget);
  });
}
