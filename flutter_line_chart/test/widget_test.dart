import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_line_chart/chart/line_chart_models.dart';
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

  testWidgets('horizontal fling continues with deceleration', (tester) async {
    final key = GlobalKey<FlutterLineChartViewState>();
    final points = List<ChartPointModel>.generate(
      240,
      (index) => ChartPointModel(x: index * 3600, y: (index % 30).toDouble()),
    );
    final model = ChartModel.fromPoints(points: points, type: XSChartType.radon)
      ..xRangeType = const XRangeType.limitedByData();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: FlutterLineChartView(key: key, model: model),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.fling(
      find.byType(FlutterLineChartView),
      const Offset(180, 0),
      1600,
    );
    await tester.pump();
    final minAfterGesture = key.currentState!.chartModel.minX;

    await tester.pump(const Duration(milliseconds: 250));
    final minAfterDeceleration = key.currentState!.chartModel.minX;

    expect(minAfterDeceleration, lessThan(minAfterGesture));
  });

  testWidgets('repeated horizontal flings can restart deceleration', (
    tester,
  ) async {
    final key = GlobalKey<FlutterLineChartViewState>();
    final points = List<ChartPointModel>.generate(
      720,
      (index) => ChartPointModel(x: index * 3600, y: (index % 30).toDouble()),
    );
    final model = ChartModel.fromPoints(points: points, type: XSChartType.radon)
      ..xRangeType = const XRangeType.limitedByData();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: FlutterLineChartView(key: key, model: model),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    for (var attempt = 0; attempt < 2; attempt += 1) {
      await tester.fling(
        find.byType(FlutterLineChartView),
        const Offset(120, 0),
        1600,
      );
      await tester.pump();
      final minAfterGesture = key.currentState!.chartModel.minX;
      await tester.pump(const Duration(milliseconds: 150));
      expect(key.currentState!.chartModel.minX, lessThan(minAfterGesture));
    }
  });

  test('all demo chart styles enable deceleration', () {
    for (final type in XSChartType.values) {
      final model = ChartModel.fromPoints(
        points: <ChartPointModel>[ChartPointModel(x: 0, y: 0)],
        type: type,
      );
      expect(model.enableDeceleration, isTrue, reason: type.name);
    }
  });

  testWidgets('pinch zoom out reaches the complete data range', (tester) async {
    final key = GlobalKey<FlutterLineChartViewState>();
    final points = List<ChartPointModel>.generate(
      241,
      (index) => ChartPointModel(x: index * 3600, y: (index % 30).toDouble()),
    );
    final model = ChartModel.fromPoints(points: points, type: XSChartType.radon)
      ..xRangeType = const XRangeType.limitedByData();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: FlutterLineChartView(key: key, model: model),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final center = tester.getCenter(find.byType(FlutterLineChartView));
    for (var attempt = 0; attempt < 3; attempt += 1) {
      final firstFinger = await tester.startGesture(
        center - const Offset(120, 0),
        pointer: attempt * 2 + 1,
      );
      final secondFinger = await tester.startGesture(
        center + const Offset(120, 0),
        pointer: attempt * 2 + 2,
      );
      await tester.pump();
      await firstFinger.moveTo(center - const Offset(8, 0));
      await secondFinger.moveTo(center + const Offset(8, 0));
      await tester.pump();
      await firstFinger.up();
      await secondFinger.up();
      await tester.pump();
    }

    expect(key.currentState!.chartModel.minX, points.first.x);
    expect(key.currentState!.chartModel.maxX, points.last.x);
  });
}
