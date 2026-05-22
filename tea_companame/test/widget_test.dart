import 'package:flutter_test/flutter_test.dart';
import 'package:tea_companame/app.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const TeaCompanameApp());
    await tester.pump();

    // Verify app title appears
    expect(find.text('TEAcompáñame'), findsOneWidget);
  });
}
