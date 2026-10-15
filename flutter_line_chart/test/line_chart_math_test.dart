import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_line_chart/chart/line_chart_math.dart';
import 'package:flutter_line_chart/chart/line_chart_models.dart';

void main() {
  List<ChartPointModel> points() => <ChartPointModel>[
    ChartPointModel(x: 1000, y: 1),
    ChartPointModel(x: 2000, y: 2),
  ];

  test('limited range clamps min to the first data point like Swift', () {
    final bounded = LineChartMath.boundXRange(
      min: 800,
      max: 1300,
      rangeType: const XRangeType.limitedByData(),
      points: points(),
    );

    expect(bounded.$1, 1000);
    expect(bounded.$2, 1300);
  });

  test('limited range clamps max to the last data point like Swift', () {
    final bounded = LineChartMath.boundXRange(
      min: 1700,
      max: 2200,
      rangeType: const XRangeType.limitedByData(),
      points: points(),
    );

    expect(bounded.$1, 1700);
    expect(bounded.$2, 2000);
  });

  test('limited range falls back to full data when span exceeds bounds', () {
    final bounded = LineChartMath.boundXRange(
      min: 500,
      max: 2500,
      rangeType: const XRangeType.limitedByData(),
      points: points(),
    );

    expect(bounded.$1, 1000);
    expect(bounded.$2, 2000);
  });

  test('LTTB keeps both data boundaries for more than 200 points', () {
    final data = List<ChartPointModel>.generate(
      6140,
      (index) =>
          ChartPointModel(x: index.toDouble(), y: (index % 37).toDouble()),
    );

    final sampled = LineChartMath.resampleLTTB(data: data, threshold: 200);

    expect(sampled.first.x, data.first.x);
    expect(sampled.last.x, data.last.x);
    expect(sampled.length, lessThanOrEqualTo(200));
    expect(sampled.length, greaterThan(190));
    expect(
      sampled.map((point) => point.x),
      orderedEquals(sampled.map((point) => point.x).toList()..sort()),
    );
  });
}
