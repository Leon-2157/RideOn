import 'package:flutter_test/flutter_test.dart';
import 'package:page_toko/main.dart';

void main() {
  testWidgets('TokoApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TokoApp());
    expect(find.byType(TokoApp), findsOneWidget);
  });
}
