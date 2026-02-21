import 'package:flutter_test/flutter_test.dart';
import 'package:night_sleep/main.dart';

void main() {
  testWidgets('Main tabs render smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NightSleepApp());
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('本地库'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    await tester.tap(find.text('本地库'));
    await tester.pumpAndSettle();
    expect(find.text('本地库'), findsWidgets);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('我的（后续扩展）'), findsOneWidget);
  });
}
