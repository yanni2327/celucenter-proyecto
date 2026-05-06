import 'package:flutter_test/flutter_test.dart';
import 'package:celucenter/main.dart';

void main() {
  testWidgets('CeluCenter smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CeluCenterApp());
    expect(find.text('CeluCenter'), findsWidgets);
  });
}