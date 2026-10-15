import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_line_chart/chart/line_chart_models.dart';
import 'package:flutter_line_chart/chart/line_chart_view.dart';
import 'package:flutter_line_chart/main.dart';

void main() {
  testWidgets('line chart demo loads', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LineChartDemoApp());
    expect(find.text('LineChartView Flutter'), findsOneWidget);

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    await tester.pump();
    expect(find.text('Radon'), findsWidgets);
    expect(find.text('Temperature'), findsOneWidget);
    expect(find.text('Humidity'), findsWidgets);
    expect(find.byType(FlutterLineChartView), findsNWidgets(3));
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

  test('chart styles match the Swift target deceleration settings', () {
    final expected = <XSChartType, bool>{
      XSChartType.radon: true,
      XSChartType.temperature: false,
      XSChartType.humidity: false,
    };
    for (final entry in expected.entries) {
      final model = ChartModel.fromPoints(
        points: <ChartPointModel>[ChartPointModel(x: 0, y: 0)],
        type: entry.key,
      );
      expect(model.enableDeceleration, entry.value, reason: entry.key.name);
    }
  });

  test('fromPoints keeps an explicit chart content inset', () {
    const inset = EdgeInsets.fromLTRB(12, 18, 24, 30);
    final model = ChartModel.fromPoints(
      points: <ChartPointModel>[ChartPointModel(x: 0, y: 0)],
      type: XSChartType.radon,
      chartContentInset: inset,
    );

    expect(model.chartContentInset, inset);
  });

  test('radon uses the Swift target default thresholds', () {
    final model = ChartModel.fromPoints(
      points: <ChartPointModel>[ChartPointModel(x: 0, y: 0)],
      type: XSChartType.radon,
    );

    expect(model.horizontalLines.map((line) => line.y), <double>[150, 75]);
  });

  test('each chart style keeps its own chart content inset', () {
    final expectedInsets = <XSChartType, EdgeInsets>{
      XSChartType.radon: const EdgeInsets.fromLTRB(40, 8, 40, 40),
      XSChartType.temperature: const EdgeInsets.fromLTRB(0, 8, 0, 40),
      XSChartType.humidity: const EdgeInsets.fromLTRB(0, 8, 0, 40),
    };

    for (final entry in expectedInsets.entries) {
      final model = ChartModel.fromPoints(
        points: <ChartPointModel>[ChartPointModel(x: 0, y: 0)],
        type: entry.key,
      );
      expect(model.chartContentInset, entry.value, reason: entry.key.name);
    }
  });

  testWidgets('chart content inset updates on the same model instance', (
    tester,
  ) async {
    final key = GlobalKey<FlutterLineChartViewState>();
    final model = ChartModel.fromPoints(
      points: <ChartPointModel>[
        ChartPointModel(x: 0, y: 0),
        ChartPointModel(x: 3600, y: 1),
      ],
      type: XSChartType.radon,
    );
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return FlutterLineChartView(key: key, model: model);
          },
        ),
      ),
    );
    await tester.pump();

    const updatedInset = EdgeInsets.fromLTRB(12, 18, 24, 30);
    rebuild(() => model.chartContentInset = updatedInset);
    await tester.pump();

    expect(key.currentState!.chartModel.chartContentInset, updatedInset);
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

  testWidgets('programmatic range changes do not report user interaction', (
    tester,
  ) async {
    final key = GlobalKey<FlutterLineChartViewState>();
    var rangeChangeCount = 0;
    var userInteractionCount = 0;
    final model = ChartModel.fromPoints(
      points: List<ChartPointModel>.generate(
        72,
        (index) => ChartPointModel(x: index * 3600, y: index.toDouble()),
      ),
      type: XSChartType.radon,
    )..xRangeType = const XRangeType.limitedByData();

    await tester.pumpWidget(
      MaterialApp(
        home: FlutterLineChartView(
          key: key,
          model: model,
          onXRangeChangedWithChart: (_, min, max) => rangeChangeCount += 1,
          onXRangeChangedByUserInteraction: (_, min, max) {
            userInteractionCount += 1;
          },
        ),
      ),
    );
    await tester.pump();
    rangeChangeCount = 0;
    userInteractionCount = 0;

    key.currentState!.changeXRange(min: 3600, max: 3600 * 25);
    await tester.pump();

    expect(rangeChangeCount, 1);
    expect(userInteractionCount, 0);
  });

  testWidgets('user fling reports its source chart', (tester) async {
    final key = GlobalKey<FlutterLineChartViewState>();
    FlutterLineChartViewState? callbackSource;
    var userInteractionCount = 0;
    final model = ChartModel.fromPoints(
      points: List<ChartPointModel>.generate(
        240,
        (index) => ChartPointModel(x: index * 3600, y: index.toDouble()),
      ),
      type: XSChartType.radon,
    )..xRangeType = const XRangeType.limitedByData();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          child: FlutterLineChartView(
            key: key,
            model: model,
            onXRangeChangedByUserInteraction: (source, min, max) {
              callbackSource = source;
              userInteractionCount += 1;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.fling(
      find.byType(FlutterLineChartView),
      const Offset(160, 0),
      1600,
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(userInteractionCount, greaterThan(0));
    expect(callbackSource, same(key.currentState));
  });

  testWidgets('flinging radon synchronizes all three demo charts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final points = List<ChartPointModel>.generate(
      240,
      (index) => ChartPointModel(x: index * 3600, y: (index % 30).toDouble()),
    );
    await tester.pumpWidget(
      LineChartDemoApp(
        initialPointsByType: {
          for (final type in XSChartType.values) type: points,
        },
      ),
    );
    final charts = find.byType(FlutterLineChartView);
    await tester.pump();

    expect(charts, findsNWidgets(3));
    await tester.fling(charts.first, const Offset(140, 0), 1600);
    await tester.pump(const Duration(milliseconds: 180));

    final states = tester
        .stateList<FlutterLineChartViewState>(charts)
        .toList(growable: false);
    expect(states, hasLength(3));
    final expectedMin = states.first.chartModel.minX;
    final expectedMax = states.first.chartModel.maxX;
    for (final state in states.skip(1)) {
      expect(state.chartModel.minX, closeTo(expectedMin, 0.001));
      expect(state.chartModel.maxX, closeTo(expectedMax, 0.001));
    }
  });
}
