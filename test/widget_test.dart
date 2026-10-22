import 'package:flutter_test/flutter_test.dart';
import 'package:zoomies/main.dart';

void main() {
  testWidgets('ZoomiesApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZoomiesApp());
    expect(find.text('Tạo Ca Khám Mới'), findsOneWidget);
  });
}
