import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_line_chart/chart/line_chart_models.dart';
import 'package:flutter_line_chart/chart/line_chart_painter.dart';

void main() {
  test('curve color changes exactly at the horizontal threshold', () async {
    const red = Color(0xffff0000);
    const green = Color(0xff00ff00);
    final model = ChartModel()
      ..chartContentInset = EdgeInsets.zero
      ..minX = 0
      ..maxX = 1
      ..minY = 0
      ..maxY = 100
      ..topAxisLineStyle = const ChartLineStyle.none()
      ..bottomAxisLineStyle = const ChartLineStyle.none()
      ..leftAxisLineStyle = const ChartLineStyle.none()
      ..rightAxisLineStyle = const ChartLineStyle.none()
      ..topAxisLabelStyle = const AxisLabelStyle.none()
      ..bottomAxisLabelStyle = const AxisLabelStyle.none()
      ..leftAxisLabelStyle = const AxisLabelStyle.none()
      ..rightAxisLabelStyle = const AxisLabelStyle.none()
      ..topAxisMaxMinStyle = const AxisLabelStyle.none()
      ..bottomAxisMaxMinStyle = const AxisLabelStyle.none()
      ..leftAxisMaxMinStyle = const AxisLabelStyle.none()
      ..rightAxisMaxMinStyle = const AxisLabelStyle.none()
      ..rightAxisDataMaxMinStyle = const AxisLabelStyle.none()
      ..horizontalLines = <HorizontalLine>[]
      ..verticalColorRanges = const <VerticalColorRange>[
        VerticalColorRange(top: 100, bottom: 50, color: red),
        VerticalColorRange(top: 50, bottom: 0, color: green),
      ];
    model.lineModel
      ..dataLineStyle = const DataLineStyle.straight(
        width: 4,
        color: Colors.black,
      )
      ..pointsShouldDraw = <ChartPointModel>[
        ChartPointModel(x: 0.5, y: 0),
        ChartPointModel(x: 0.5, y: 100),
      ];

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    LineChartPainter(
      chartModel: model,
      horizontalLineFormatter: (value) => '$value',
      tappedItemFormatter: (_) => const <String>[],
      rightAxisDataMaxMinFormatter: (min, max) => MaxMinModel(max: '', min: ''),
    ).paint(canvas, const Size(100, 100));
    final image = await recorder.endRecording().toImage(100, 100);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    addTearDown(image.dispose);

    Color pixelAt(int x, int y) {
      final offset = (y * image.width + x) * 4;
      return Color.fromARGB(
        bytes!.getUint8(offset + 3),
        bytes.getUint8(offset),
        bytes.getUint8(offset + 1),
        bytes.getUint8(offset + 2),
      );
    }

    expect(pixelAt(50, 48), red);
    expect(pixelAt(50, 52), green);
  });

  test('bottom max min labels are drawn below the bottom axis', () async {
    final model = ChartModel()
      ..chartContentInset = const EdgeInsets.fromLTRB(0, 0, 0, 40)
      ..minX = 0
      ..maxX = 1
      ..minY = 0
      ..maxY = 1
      ..topAxisLineStyle = const ChartLineStyle.none()
      ..bottomAxisLineStyle = const ChartLineStyle.line(
        width: 1,
        color: Colors.black,
      )
      ..leftAxisLineStyle = const ChartLineStyle.none()
      ..rightAxisLineStyle = const ChartLineStyle.none()
      ..topAxisLabelStyle = const AxisLabelStyle.none()
      ..bottomAxisLabelStyle = const AxisLabelStyle.none()
      ..leftAxisLabelStyle = const AxisLabelStyle.none()
      ..rightAxisLabelStyle = const AxisLabelStyle.none()
      ..topAxisMaxMinStyle = const AxisLabelStyle.none()
      ..bottomAxisMaxMinStyle = const AxisLabelStyle.bottom(
        color: Colors.black,
        fontSize: 12,
      )
      ..leftAxisMaxMinStyle = const AxisLabelStyle.none()
      ..rightAxisMaxMinStyle = const AxisLabelStyle.none()
      ..rightAxisDataMaxMinStyle = const AxisLabelStyle.none()
      ..horizontalLines = <HorizontalLine>[]
      ..verticalColorRanges = <VerticalColorRange>[];

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    LineChartPainter(
      chartModel: model,
      horizontalLineFormatter: (value) => '$value',
      tappedItemFormatter: (_) => const <String>[],
      rightAxisDataMaxMinFormatter: (min, max) => MaxMinModel(max: '', min: ''),
      bottomAxisMaxMinFormatter: (x) => x == 0 ? 'MIN' : 'MAX',
    ).paint(canvas, const Size(100, 100));
    final image = await recorder.endRecording().toImage(100, 100);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    addTearDown(image.dispose);

    bool hasInkBetween(int top, int bottom) {
      for (var y = top; y <= bottom; y += 1) {
        for (var x = 0; x < image.width; x += 1) {
          final alphaOffset = (y * image.width + x) * 4 + 3;
          if (bytes!.getUint8(alphaOffset) > 0) {
            return true;
          }
        }
      }
      return false;
    }

    expect(hasInkBetween(58, 62), isTrue);
    expect(hasInkBetween(63, 99), isTrue);
  });

  test('rich horizontal line formatter controls text color and size', () async {
    final model = ChartModel()
      ..chartContentInset = const EdgeInsets.fromLTRB(40, 8, 0, 20)
      ..minX = 0
      ..maxX = 1
      ..minY = 0
      ..maxY = 100
      ..topAxisLineStyle = const ChartLineStyle.none()
      ..bottomAxisLineStyle = const ChartLineStyle.none()
      ..leftAxisLineStyle = const ChartLineStyle.none()
      ..rightAxisLineStyle = const ChartLineStyle.none()
      ..topAxisLabelStyle = const AxisLabelStyle.none()
      ..bottomAxisLabelStyle = const AxisLabelStyle.none()
      ..leftAxisLabelStyle = const AxisLabelStyle.none()
      ..rightAxisLabelStyle = const AxisLabelStyle.none()
      ..topAxisMaxMinStyle = const AxisLabelStyle.none()
      ..bottomAxisMaxMinStyle = const AxisLabelStyle.none()
      ..leftAxisMaxMinStyle = const AxisLabelStyle.none()
      ..rightAxisMaxMinStyle = const AxisLabelStyle.none()
      ..rightAxisDataMaxMinStyle = const AxisLabelStyle.none()
      ..verticalColorRanges = <VerticalColorRange>[]
      ..horizontalLines = const <HorizontalLine>[
        HorizontalLine(
          y: 50,
          lineStyle: ChartLineStyle.none(),
          labelStyle: AxisLabelStyle.left(color: Colors.black, fontSize: 8),
        ),
      ];

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    LineChartPainter(
      chartModel: model,
      horizontalLineTextFormatter: (_) => const TextSpan(
        text: 'RICH',
        style: TextStyle(
          color: Colors.red,
          fontSize: 28,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    ).paint(canvas, const Size(120, 100));
    final image = await recorder.endRecording().toImage(120, 100);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    addTearDown(image.dispose);

    var redPixels = 0;
    for (var offset = 0; offset < bytes!.lengthInBytes; offset += 4) {
      final red = bytes.getUint8(offset);
      final green = bytes.getUint8(offset + 1);
      final blue = bytes.getUint8(offset + 2);
      final alpha = bytes.getUint8(offset + 3);
      if (red > 180 && green < 100 && blue < 100 && alpha > 0) {
        redPixels += 1;
      }
    }

    expect(redPixels, greaterThan(20));
  });
}
