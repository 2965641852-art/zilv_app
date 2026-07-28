import 'package:flutter_test/flutter_test.dart';
import 'package:zilv_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZilvApp());
    expect(find.text('待办清单'), findsOneWidget);
  });
}
