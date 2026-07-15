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
}
