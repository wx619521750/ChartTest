import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_line_chart/chart/line_chart_view.dart';
import 'package:flutter_line_chart/main.dart';

void main() {
  testWidgets('line chart demo loads', (tester) async {
    await tester.pumpWidget(const LineChartDemoApp());
    expect(find.text('LineChartView Flutter'), findsOneWidget);

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    await tester.pump();
    expect(find.text('Radon'), findsWidgets);
    expect(find.byType(FlutterLineChartView), findsOneWidget);
  });
}
