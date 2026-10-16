import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'line_chart_math.dart';
import 'line_chart_models.dart';

typedef HorizontalLineFormatter = String Function(double y);
typedef TappedItemFormatter = List<String> Function(ChartPointModel item);
typedef RightAxisDataMaxMinFormatter =
    MaxMinModel Function(double min, double max);
typedef AxisGraduationFormatter =
    String? Function(AxisLabelPlacement direction, double value);
typedef BottomAxisMaxMinFormatter = String Function(double x);
typedef HorizontalLineTextFormatter = TextSpan Function(double y);
typedef TappedItemTextFormatter = XYTextModel Function(ChartPointModel item);
typedef RightAxisDataMaxMinTextFormatter =
    MaxMinTextModel Function(double min, double max);
typedef RightAxisDataAverageFormatter = String Function(double value);
typedef RightAxisDataAverageTextFormatter = TextSpan Function(double value);
typedef AxisGraduationTextFormatter =
    TextSpan? Function(AxisLabelPlacement direction, double value);
typedef BottomAxisMaxMinTextFormatter = TextSpan Function(double x);
typedef DateAdaptStampsFormatter =
    DateAdaptStampsModel? Function(double minX, double maxX);

enum _TextAnchor {
  minXMinY,
  maxXMinY,
  minXMaxY,
  maxXMaxY,
  centerXMinY,
  minXCenterY,
  maxXCenterY,
  centerXMaxY,
  center,
}

class LineChartPainter extends CustomPainter {
  LineChartPainter({
    required this.chartModel,
    this.horizontalLineFormatter,
    this.tappedItemFormatter,
    this.rightAxisDataMaxMinFormatter,
    this.axisGraduationFormatter,
    this.bottomAxisMaxMinFormatter,
    this.horizontalLineTextFormatter,
    this.tappedItemTextFormatter,
    this.rightAxisDataMaxMinTextFormatter,
    this.rightAxisDataAverageFormatter,
    this.rightAxisDataAverageTextFormatter,
    this.axisGraduationTextFormatter,
    this.bottomAxisMaxMinTextFormatter,
    this.dateAdaptStampsFormatter,
  });

  final ChartModel chartModel;
  final HorizontalLineFormatter? horizontalLineFormatter;
  final TappedItemFormatter? tappedItemFormatter;
  final RightAxisDataMaxMinFormatter? rightAxisDataMaxMinFormatter;
  final AxisGraduationFormatter? axisGraduationFormatter;
  final BottomAxisMaxMinFormatter? bottomAxisMaxMinFormatter;
  final HorizontalLineTextFormatter? horizontalLineTextFormatter;
  final TappedItemTextFormatter? tappedItemTextFormatter;
  final RightAxisDataMaxMinTextFormatter? rightAxisDataMaxMinTextFormatter;
  final RightAxisDataAverageFormatter? rightAxisDataAverageFormatter;
  final RightAxisDataAverageTextFormatter? rightAxisDataAverageTextFormatter;
  final AxisGraduationTextFormatter? axisGraduationTextFormatter;
  final BottomAxisMaxMinTextFormatter? bottomAxisMaxMinTextFormatter;
  final DateAdaptStampsFormatter? dateAdaptStampsFormatter;
  late Size _lastPaintSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }
    _lastPaintSize = size;
    _drawAxis(canvas, size);
    _drawLine(canvas, size);
    _drawEmptyArea(canvas, size);
    _drawAxisLabels(canvas, size);
    _drawAxisMaxMinLabels(canvas, size);
    _drawAxisDataMaxMinLabels(canvas, size);
    _drawAxisDataAverageLabel(canvas, size);
    _drawHVLines(canvas, size);
    _drawSelectedItem(canvas, size);
  }

  void _drawAxis(Canvas canvas, Size size) {
    final inset = chartModel.chartContentInset;
    final rect = LineChartMath.chartRect(chartModel, size);
    _drawStyledLine(
      canvas,
      chartModel.topAxisLineStyle,
      Offset(chartModel.horizontalAxisFullFrame ? 0 : rect.left, inset.top),
      Offset(
        chartModel.horizontalAxisFullFrame ? size.width : rect.right,
        inset.top,
      ),
    );
    _drawStyledLine(
      canvas,
      chartModel.bottomAxisLineStyle,
      Offset(
        chartModel.horizontalAxisFullFrame ? 0 : rect.left,
        size.height - inset.bottom,
      ),
      Offset(
        chartModel.horizontalAxisFullFrame ? size.width : rect.right,
        size.height - inset.bottom,
      ),
    );
    _drawStyledLine(
      canvas,
      chartModel.leftAxisLineStyle,
      Offset(inset.left, chartModel.verticalAxisFullFrame ? 0 : rect.top),
      Offset(
        inset.left,
        chartModel.verticalAxisFullFrame ? size.height : rect.bottom,
      ),
    );
    _drawStyledLine(
      canvas,
      chartModel.rightAxisLineStyle,
      Offset(
        size.width - inset.right,
        chartModel.verticalAxisFullFrame ? 0 : rect.top,
      ),
      Offset(
        size.width - inset.right,
        chartModel.verticalAxisFullFrame ? size.height : rect.bottom,
      ),
    );
  }

  void _drawLine(Canvas canvas, Size size) {
    final data = chartModel.lineModel.pointsShouldDraw;
    if (data.isEmpty) {
      return;
    }

    final rect = LineChartMath.chartRect(chartModel, size);
    final lineWidth = chartModel.lineModel.dataLineStyle.width;
    final clipRect = Rect.fromLTRB(
      rect.left,
      rect.top - lineWidth * 0.5,
      rect.right,
      rect.bottom + lineWidth * 0.5,
    );
    final paths = _buildLinePaths(size, data);
    final areaPaths = _buildAreaPaths(size, data);
    if (paths.isEmpty) {
      return;
    }

    canvas.save();
    canvas.clipRect(clipRect);
    final fallbackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = chartModel.lineModel.dataLineStyle.color;
    for (final path in paths) {
      canvas.drawPath(path, fallbackPaint);
    }
    canvas.restore();

    final shadow = chartModel.lineModel.dataLineShadow;
    if (shadow != null && shadow.blur >= 0) {
      final shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = shadow.color
        ..maskFilter = shadow.blur > 0
            ? MaskFilter.blur(BlurStyle.normal, shadow.blur)
            : null;
      canvas.save();
      canvas.translate(shadow.offset.dx, shadow.offset.dy);
      canvas.clipRect(clipRect);
      for (final path in paths) {
        canvas.drawPath(path, shadowPaint);
      }
      canvas.restore();
    }

    final backgroundRanges = chartModel.verticalBackgroundColorRanges;
    if (backgroundRanges != null && backgroundRanges.isNotEmpty) {
      for (final range in backgroundRanges) {
        final top = LineChartMath.pointToOffset(
          chartModel,
          size,
          0,
          range.top,
        ).dy;
        final bottom = LineChartMath.pointToOffset(
          chartModel,
          size,
          0,
          range.bottom,
        ).dy;
        final band = Rect.fromLTRB(
          rect.left,
          math.min(top, bottom),
          rect.right,
          math.max(top, bottom),
        );
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [range.topColor, range.bottomColor],
          ).createShader(band);
        canvas.save();
        canvas.clipRect(clipRect);
        for (final areaPath in areaPaths) {
          canvas.save();
          canvas.clipPath(areaPath);
          canvas.drawRect(band, paint);
          canvas.restore();
        }
        canvas.restore();
      }
    }

    final colorRanges = chartModel.verticalColorRanges;
    for (var index = 0; index < colorRanges.length; index += 1) {
      final range = colorRanges[index];
      final top = LineChartMath.pointToOffset(
        chartModel,
        size,
        0,
        range.top,
      ).dy;
      final bottom = LineChartMath.pointToOffset(
        chartModel,
        size,
        0,
        range.bottom,
      ).dy;
      var bandTop = math.min(top, bottom);
      var bandBottom = math.max(top, bottom);
      if (index == 0) {
        bandTop -= lineWidth * 0.5;
      }
      if (index == colorRanges.length - 1) {
        bandBottom += lineWidth;
      }
      final band = Rect.fromLTRB(rect.left, bandTop, rect.right, bandBottom);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [range.topColor, range.bottomColor],
        ).createShader(band);
      canvas.save();
      canvas.clipRect(clipRect);
      canvas.clipRect(band, doAntiAlias: false);
      for (final path in paths) {
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  List<Path> _buildAreaPaths(Size size, List<ChartPointModel> data) {
    final paths = <Path>[];
    var segment = <ChartPointModel>[];
    void flushSegment() {
      if (segment.length < 2) {
        segment = <ChartPointModel>[];
        return;
      }
      final points = segment
          .map(
            (item) =>
                LineChartMath.pointToOffset(chartModel, size, item.x, item.y),
          )
          .toList();
      final rect = LineChartMath.chartRect(chartModel, size);
      final path = Path()
        ..moveTo(points.first.dx, rect.bottom)
        ..lineTo(points.first.dx, points.first.dy);
      _appendSegmentCommands(path, points);
      path
        ..lineTo(points.last.dx, rect.bottom)
        ..close();
      paths.add(path);
      segment = <ChartPointModel>[];
    }

    for (final item in data) {
      if (item.dataType == ChartPointDataType.gap) {
        flushSegment();
      } else {
        segment.add(item);
      }
    }
    flushSegment();
    return paths;
  }

  void _appendSegmentCommands(Path path, List<Offset> points) {
    final style = chartModel.lineModel.dataLineStyle;
    switch (style.kind) {
      case DataLineKind.straight:
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
      case DataLineKind.bezier:
        for (var index = 1; index < points.length; index += 1) {
          final start = points[index - 1];
          final end = points[index];
          final dx = end.dx - start.dx;
          _appendCurveOrLine(
            path,
            start: start,
            end: end,
            control1: Offset(start.dx + dx * 0.5, start.dy),
            control2: Offset(end.dx - dx * 0.5, end.dy),
          );
        }
      case DataLineKind.monotoneCubic:
        final controls = _monotoneCubicControlPoints(points);
        for (var index = 0; index < controls.length; index += 1) {
          _appendCurveOrLine(
            path,
            start: points[index],
            end: points[index + 1],
            control1: controls[index].$1,
            control2: controls[index].$2,
          );
        }
      case DataLineKind.catmullRom:
        final controls = _catmullRomControlPoints(points);
        for (var index = 0; index < controls.length; index += 1) {
          _appendCurveOrLine(
            path,
            start: points[index],
            end: points[index + 1],
            control1: controls[index].$1,
            control2: controls[index].$2,
          );
        }
    }
  }

  List<Path> _buildLinePaths(Size size, List<ChartPointModel> data) {
    final paths = <Path>[];
    var segment = <ChartPointModel>[];

    void flushSegment() {
      if (segment.isEmpty) {
        return;
      }
      final points = segment
          .map(
            (item) =>
                LineChartMath.pointToOffset(chartModel, size, item.x, item.y),
          )
          .toList();
      paths.add(_buildSegmentPath(points));
      segment = <ChartPointModel>[];
    }

    for (final item in data) {
      if (item.dataType == ChartPointDataType.gap) {
        flushSegment();
        continue;
      }
      segment.add(item);
    }
    flushSegment();
    return paths;
  }

  Path _buildSegmentPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length < 2) {
      return path;
    }

    final style = chartModel.lineModel.dataLineStyle;
    switch (style.kind) {
      case DataLineKind.straight:
        for (final point in points.skip(1)) {
          path.lineTo(point.dx, point.dy);
        }
      case DataLineKind.bezier:
        for (var index = 1; index < points.length; index += 1) {
          final start = points[index - 1];
          final end = points[index];
          final dx = end.dx - start.dx;
          _appendCurveOrLine(
            path,
            start: start,
            end: end,
            control1: Offset(start.dx + dx * 0.5, start.dy),
            control2: Offset(end.dx - dx * 0.5, end.dy),
          );
        }
      case DataLineKind.monotoneCubic:
        final controls = _monotoneCubicControlPoints(points);
        for (var index = 0; index < controls.length; index += 1) {
          _appendCurveOrLine(
            path,
            start: points[index],
            end: points[index + 1],
            control1: controls[index].$1,
            control2: controls[index].$2,
          );
        }
      case DataLineKind.catmullRom:
        final controls = _catmullRomControlPoints(points);
        for (var index = 0; index < controls.length; index += 1) {
          _appendCurveOrLine(
            path,
            start: points[index],
            end: points[index + 1],
            control1: controls[index].$1,
            control2: controls[index].$2,
          );
        }
    }
    return path;
  }

  void _appendCurveOrLine(
    Path path, {
    required Offset start,
    required Offset end,
    required Offset control1,
    required Offset control2,
  }) {
    if (chartModel.bezierToLineMinDistance > 0 &&
        (end.dx - start.dx).abs() < chartModel.bezierToLineMinDistance) {
      path.lineTo(end.dx, end.dy);
      return;
    }
    path.cubicTo(
      control1.dx,
      control1.dy,
      control2.dx,
      control2.dy,
      end.dx,
      end.dy,
    );
  }

  List<(Offset, Offset)> _monotoneCubicControlPoints(List<Offset> points) {
    if (points.length < 2) {
      return <(Offset, Offset)>[];
    }
    const minimumDistance = 0.0001;
    final intervals = <double>[];
    final slopes = <double>[];
    for (var index = 0; index < points.length - 1; index += 1) {
      final dx = points[index + 1].dx - points[index].dx;
      intervals.add(dx);
      slopes.add(
        dx > minimumDistance
            ? (points[index + 1].dy - points[index].dy) / dx
            : 0,
      );
    }
    final tangents = List<double>.filled(points.length, 0);
    tangents.first = slopes.first;
    tangents.last = slopes.last;
    for (var index = 1; index < tangents.length - 1; index += 1) {
      final previousSlope = slopes[index - 1];
      final nextSlope = slopes[index];
      if (previousSlope * nextSlope <= 0) {
        tangents[index] = 0;
        continue;
      }
      final previousInterval = math.max(intervals[index - 1], minimumDistance);
      final nextInterval = math.max(intervals[index], minimumDistance);
      final firstWeight = 2 * nextInterval + previousInterval;
      final secondWeight = nextInterval + 2 * previousInterval;
      tangents[index] =
          (firstWeight + secondWeight) /
          (firstWeight / previousSlope + secondWeight / nextSlope);
    }
    return List<(Offset, Offset)>.generate(points.length - 1, (index) {
      final distance = intervals[index] / 3;
      return (
        Offset(
          points[index].dx + distance,
          points[index].dy + tangents[index] * distance,
        ),
        Offset(
          points[index + 1].dx - distance,
          points[index + 1].dy - tangents[index + 1] * distance,
        ),
      );
    });
  }

  List<(Offset, Offset)> _catmullRomControlPoints(List<Offset> points) {
    if (points.length < 2) {
      return <(Offset, Offset)>[];
    }
    final controls = <(Offset, Offset)>[];
    for (var index = 0; index < points.length - 1; index += 1) {
      final point1 = points[index];
      final point2 = points[index + 1];
      final point0 = index > 0
          ? points[index - 1]
          : Offset(2 * point1.dx - point2.dx, 2 * point1.dy - point2.dy);
      final point3 = index + 2 < points.length
          ? points[index + 2]
          : Offset(2 * point2.dx - point1.dx, 2 * point2.dy - point1.dy);
      final time0 = 0.0;
      final time1 = time0 + _catmullRomParameterDistance(point0, point1);
      final time2 = time1 + _catmullRomParameterDistance(point1, point2);
      final time3 = time2 + _catmullRomParameterDistance(point2, point3);
      final duration = time2 - time1;
      final tangent1 = _catmullRomTangent(
        point0,
        point1,
        point2,
        time0,
        time1,
        time2,
      );
      final tangent2 = _catmullRomTangent(
        point1,
        point2,
        point3,
        time1,
        time2,
        time3,
      );
      final minimumX = math.min(point1.dx, point2.dx);
      final maximumX = math.max(point1.dx, point2.dx);
      controls.add((
        Offset(
          math.min(
            maximumX,
            math.max(minimumX, point1.dx + tangent1.dx * duration / 3),
          ),
          point1.dy + tangent1.dy * duration / 3,
        ),
        Offset(
          math.min(
            maximumX,
            math.max(minimumX, point2.dx - tangent2.dx * duration / 3),
          ),
          point2.dy - tangent2.dy * duration / 3,
        ),
      ));
    }
    return controls;
  }

  Offset _catmullRomTangent(
    Offset previous,
    Offset current,
    Offset next,
    double previousTime,
    double currentTime,
    double nextTime,
  ) {
    final previousDuration = currentTime - previousTime;
    final nextDuration = nextTime - currentTime;
    final totalDuration = nextTime - previousTime;
    return Offset(
      (current.dx - previous.dx) / previousDuration -
          (next.dx - previous.dx) / totalDuration +
          (next.dx - current.dx) / nextDuration,
      (current.dy - previous.dy) / previousDuration -
          (next.dy - previous.dy) / totalDuration +
          (next.dy - current.dy) / nextDuration,
    );
  }

  double _catmullRomParameterDistance(Offset start, Offset end) {
    return math.max(math.sqrt((end - start).distance), 0.0001);
  }

  void _drawEmptyArea(Canvas canvas, Size size) {
    if (chartModel.gapStyle.kind != GapKind.distance) {
      return;
    }
    final rect = LineChartMath.chartRect(chartModel, size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xffeaeaea);

    canvas.save();
    canvas.clipRect(rect);
    for (final area in chartModel.lineModel.emptyAreas) {
      final left = LineChartMath.pointToOffset(
        chartModel,
        size,
        area.left,
        0,
      ).dx.clamp(rect.left, rect.right);
      final right = LineChartMath.pointToOffset(
        chartModel,
        size,
        area.right,
        0,
      ).dx.clamp(rect.left, rect.right);
      final gapRect = Rect.fromLTRB(
        left.toDouble(),
        rect.top,
        right.toDouble(),
        rect.bottom,
      );
      if (gapRect.width <= 0) {
        continue;
      }
      var y = gapRect.top - gapRect.width;
      while (y <= gapRect.bottom) {
        canvas.drawLine(
          Offset(gapRect.left, y),
          Offset(gapRect.right, y + gapRect.width),
          paint,
        );
        y += 10;
      }
      if (gapRect.width > 10) {
        _drawText(
          canvas,
          'G\nA\nP',
          gapRect.center,
          _TextAnchor.center,
          const TextStyle(
            color: Color(0xff999999),
            fontSize: 13,
            height: 1.05,
            letterSpacing: 0,
          ),
        );
      }
    }
    canvas.restore();
  }

  void _drawAxisLabels(Canvas canvas, Size size) {
    final rect = LineChartMath.chartRect(chartModel, size);
    final inset = chartModel.chartContentInset;
    if (chartModel.bottomAxisStepType.kind == AxisStepKind.dateAdapt &&
        chartModel.bottomAxisLabelStyle.placement ==
            AxisLabelPlacement.bottom) {
      final ticks =
          dateAdaptStampsFormatter?.call(chartModel.minX, chartModel.maxX) ??
          LineChartMath.getDateAdaptStamps(chartModel, size);
      for (final stamp in ticks.stamps) {
        final x = LineChartMath.pointToOffset(chartModel, size, stamp, 0).dx;
        final y =
            size.height - inset.bottom + chartModel.bottomAxisLabelStyle.offset;
        final text =
            axisGraduationTextFormatter?.call(
              AxisLabelPlacement.bottom,
              stamp,
            ) ??
            TextSpan(
              text:
                  axisGraduationFormatter?.call(
                    AxisLabelPlacement.bottom,
                    stamp,
                  ) ??
                  LineChartMath.formatDate(stamp, ticks.format),
            );
        _drawText(
          canvas,
          text,
          Offset(x, y),
          _TextAnchor.centerXMinY,
          chartModel.bottomAxisLabelStyle.textStyle,
        );
        _drawGraduation(canvas, Offset(x, size.height - inset.bottom), true);
      }
    }

    final steps = LineChartMath.generateAxisSteps(
      min: chartModel.minY,
      max: chartModel.maxY,
      type: chartModel.rightAxisStepType,
    );
    if (chartModel.rightAxisLabelStyle.isVisible) {
      for (final item in steps) {
        final y = LineChartMath.pointToOffset(chartModel, size, 0, item).dy;
        final x =
            size.width - inset.right + chartModel.rightAxisLabelStyle.offset;
        final text =
            axisGraduationTextFormatter?.call(AxisLabelPlacement.right, item) ??
            TextSpan(
              text:
                  axisGraduationFormatter?.call(
                    AxisLabelPlacement.right,
                    item,
                  ) ??
                  item.toStringAsFixed(1),
            );
        final anchor =
            chartModel.rightAxisLabelStyle.placement == AxisLabelPlacement.left
            ? _TextAnchor.maxXCenterY
            : _TextAnchor.minXCenterY;
        _drawText(
          canvas,
          text,
          Offset(x, y),
          anchor,
          chartModel.rightAxisLabelStyle.textStyle,
        );
        _drawGraduation(canvas, Offset(rect.right, y), false);
      }
    }

    final bottomStyle = chartModel.bottomAxisLabelStyle;
    if (bottomStyle.placement == AxisLabelPlacement.bottom &&
        chartModel.bottomAxisStepType.kind != AxisStepKind.dateAdapt) {
      final stepType = chartModel.bottomAxisStepType;
      final steps = stepType.kind == AxisStepKind.separateCountWithAllData
          ? LineChartMath.generateBottomAxisStepsWithAllData(
              chartModel,
              stepType.count,
            )
          : LineChartMath.generateAxisSteps(
              min: chartModel.minX,
              max: chartModel.maxX,
              type: stepType,
            );
      for (final value in steps) {
        final x = LineChartMath.pointToOffset(chartModel, size, value, 0).dx;
        final y = size.height - inset.bottom + bottomStyle.offset;
        final text =
            axisGraduationTextFormatter?.call(
              AxisLabelPlacement.bottom,
              value,
            ) ??
            TextSpan(text: value.toStringAsFixed(1));
        _drawText(
          canvas,
          text,
          Offset(x, y),
          _TextAnchor.centerXMinY,
          bottomStyle.textStyle,
        );
        _drawGraduation(canvas, Offset(x, rect.bottom), true);
      }
    }
  }

  void _drawGraduation(Canvas canvas, Offset origin, bool bottomAxis) {
    final style = bottomAxis
        ? chartModel.bottomGraduationType
        : chartModel.rightGraduationType;
    if (style.kind == GraduationKind.none) {
      return;
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.width
      ..color = style.color;
    final rect = LineChartMath.chartRect(chartModel, _lastPaintSize);
    final length =
        style.length ??
        (bottomAxis ? rect.bottom - rect.top : rect.right - rect.left);
    final end = bottomAxis
        ? Offset(origin.dx, rect.bottom - length)
        : Offset(rect.right - length, origin.dy);
    if (style.kind == GraduationKind.dashLine && style.dashPattern.isNotEmpty) {
      _drawDashedLine(canvas, origin, end, paint, style.dashPattern);
      return;
    }
    if (bottomAxis) {
      canvas.drawLine(origin, end, paint);
    } else {
      canvas.drawLine(origin, end, paint);
    }
  }

  void _drawAxisMaxMinLabels(Canvas canvas, Size size) {
    final inset = chartModel.chartContentInset;
    final rect = LineChartMath.chartRect(chartModel, size);
    if (chartModel.bottomAxisMaxMinStyle.placement ==
        AxisLabelPlacement.bottom) {
      final y = size.height - chartModel.bottomAxisMaxMinStyle.offset;
      final minText =
          bottomAxisMaxMinTextFormatter?.call(chartModel.minX) ??
          TextSpan(
            text:
                bottomAxisMaxMinFormatter?.call(chartModel.minX) ??
                LineChartMath.formatDate(
                  chartModel.minX,
                  'yyyy-MM-dd HH:mm:ss',
                ),
          );
      final maxText =
          bottomAxisMaxMinTextFormatter?.call(chartModel.maxX) ??
          TextSpan(
            text:
                bottomAxisMaxMinFormatter?.call(chartModel.maxX) ??
                LineChartMath.formatDate(
                  chartModel.maxX,
                  'yyyy-MM-dd HH:mm:ss',
                ),
          );
      _drawText(
        canvas,
        minText,
        Offset(chartModel.horizontalAxisFullFrame ? 0 : rect.left, y),
        _TextAnchor.minXMaxY,
        chartModel.bottomAxisMaxMinStyle.textStyle,
      );
      _drawText(
        canvas,
        maxText,
        Offset(chartModel.horizontalAxisFullFrame ? size.width : rect.right, y),
        _TextAnchor.maxXMaxY,
        chartModel.bottomAxisMaxMinStyle.textStyle,
      );
    }

    if (chartModel.rightAxisMaxMinStyle.isVisible) {
      final x =
          size.width - inset.right + chartModel.rightAxisMaxMinStyle.offset;
      final style = chartModel.rightAxisMaxMinStyle.textStyle;
      _drawText(
        canvas,
        chartModel.minY.toStringAsFixed(1),
        Offset(x, rect.bottom),
        _TextAnchor.maxXMaxY,
        style,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        clampRect: rect,
      );
      _drawText(
        canvas,
        chartModel.maxY.toStringAsFixed(1),
        Offset(x, rect.top),
        _TextAnchor.maxXMinY,
        style,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        clampRect: rect,
      );
    }
  }

  void _drawAxisDataMaxMinLabels(Canvas canvas, Size size) {
    final visibleData = chartModel.lineModel.pointsShouldDraw
        .where(
          (point) =>
              point.x >= chartModel.minX &&
              point.x <= chartModel.maxX &&
              point.dataType == ChartPointDataType.data,
        )
        .toList();
    if (visibleData.isEmpty || !chartModel.rightAxisDataMaxMinStyle.isVisible) {
      return;
    }

    final ys = visibleData.map((point) => point.y).toList();
    final dataMinY = ys.reduce(math.min);
    final dataMaxY = ys.reduce(math.max);
    final labels = _rightAxisDataMaxMinText(dataMinY, dataMaxY);
    final positions = _rightAxisDataMaxMinDrawY(size, visibleData);
    final rect = LineChartMath.chartRect(chartModel, size);
    final x =
        size.width -
        chartModel.chartContentInset.right +
        chartModel.rightAxisDataMaxMinStyle.offset;
    final anchor =
        chartModel.rightAxisDataMaxMinStyle.placement ==
            AxisLabelPlacement.right
        ? _TextAnchor.minXCenterY
        : _TextAnchor.maxXCenterY;
    final minSize = _drawText(
      canvas,
      labels.min,
      Offset(x, positions.$1),
      anchor,
      chartModel.rightAxisDataMaxMinStyle.textStyle,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      clampRect: rect,
    );
    final maxSize = _drawText(
      canvas,
      labels.max,
      Offset(x, positions.$2),
      anchor,
      chartModel.rightAxisDataMaxMinStyle.textStyle,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      clampRect: rect,
    );

    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xffc4c4c4).withValues(alpha: 0.5);
    final minPoint = LineChartMath.pointToOffset(chartModel, size, 0, dataMinY);
    final maxPoint = LineChartMath.pointToOffset(chartModel, size, 0, dataMaxY);
    final minLineEnd = anchor == _TextAnchor.maxXCenterY
        ? x - minSize.width
        : x;
    final maxLineEnd = anchor == _TextAnchor.maxXCenterY
        ? x - maxSize.width
        : x;
    _drawDashedLine(
      canvas,
      Offset(rect.left, minPoint.dy),
      Offset(minLineEnd, minPoint.dy),
      dashPaint,
      const [6, 3],
    );
    _drawDashedLine(
      canvas,
      Offset(rect.left, maxPoint.dy),
      Offset(maxLineEnd, maxPoint.dy),
      dashPaint,
      const [6, 3],
    );
  }

  void _drawAxisDataAverageLabel(Canvas canvas, Size size) {
    final labelStyle = chartModel.rightAxisDataAverageStyle;
    if (!labelStyle.isVisible) {
      return;
    }
    final visibleData = chartModel.lineModel.pointsShouldDraw
        .where(
          (point) =>
              point.x >= chartModel.minX &&
              point.x <= chartModel.maxX &&
              point.dataType == ChartPointDataType.data,
        )
        .toList();
    if (visibleData.isEmpty) {
      return;
    }
    final average =
        visibleData.map((point) => point.y).reduce((a, b) => a + b) /
        visibleData.length;
    final rect = LineChartMath.chartRect(chartModel, size);
    final point = LineChartMath.pointToOffset(chartModel, size, 0, average);
    final x =
        size.width - chartModel.chartContentInset.right + labelStyle.offset;
    final anchor = labelStyle.placement == AxisLabelPlacement.right
        ? _TextAnchor.minXCenterY
        : _TextAnchor.maxXCenterY;
    final text =
        rightAxisDataAverageTextFormatter?.call(average) ??
        TextSpan(
          text:
              rightAxisDataAverageFormatter?.call(average) ??
              average.toStringAsFixed(1),
        );
    final textSize = _drawText(
      canvas,
      text,
      Offset(x, point.dy),
      anchor,
      labelStyle.textStyle,
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      cornerRadius: 0,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xffc4c4c4).withValues(alpha: 0.5);
    final lineEnd = anchor == _TextAnchor.maxXCenterY
        ? x - textSize.width
        : rect.right;
    _drawDashedLine(
      canvas,
      Offset(rect.left, point.dy),
      Offset(lineEnd, point.dy),
      paint,
      const [6, 3],
    );
  }

  (double, double) _rightAxisDataMaxMinDrawY(
    Size size,
    List<ChartPointModel> visibleData,
  ) {
    final rect = LineChartMath.chartRect(chartModel, size);
    final style = chartModel.rightAxisDataMaxMinStyle.textStyle;
    final strSize = LineChartMath.textSize('00.00', style);
    final ys = visibleData.map((point) => point.y).toList();
    final dataMinY = ys.reduce(math.min);
    final dataMaxY = ys.reduce(math.max);
    var minY = LineChartMath.pointToOffset(chartModel, size, 0, dataMinY).dy;
    var maxY = LineChartMath.pointToOffset(chartModel, size, 0, dataMaxY).dy;
    const distance = 0.0;
    final minAllowed = rect.top + strSize.height * 0.5;
    final maxAllowed = rect.bottom - strSize.height * 0.5;

    if (minY >= maxAllowed) {
      minY = maxAllowed;
      if (maxY >= minY - strSize.height - distance) {
        maxY = minY - strSize.height - distance;
      }
    } else if (maxY <= minAllowed) {
      maxY = minAllowed;
      if (minY <= maxY + strSize.height + distance) {
        minY = maxY + strSize.height + distance;
      }
    } else if (minY - maxY < strSize.height + distance * 2) {
      final mid = rect.top + (minY + maxY - 2 * rect.top) * 0.5;
      minY = mid + distance * 0.5 + strSize.height * 0.5;
      maxY = mid - distance * 0.5 - strSize.height * 0.5;
      if (minY >= maxAllowed) {
        minY = maxAllowed;
        maxY = minY - strSize.height - distance;
      } else if (maxY <= minAllowed) {
        maxY = minAllowed;
        minY = maxY + strSize.height + distance;
      }
    }
    return (minY, maxY);
  }

  void _drawHVLines(Canvas canvas, Size size) {
    final rect = LineChartMath.chartRect(chartModel, size);
    const padding = EdgeInsets.symmetric(horizontal: 6, vertical: 4);
    final lineLabelPositions = _horizontalLinesMaxMinDrawY(
      size,
      padding: padding,
      distance: 4,
    );
    final minLineY = chartModel.horizontalLines.isEmpty
        ? 0.0
        : chartModel.horizontalLines.map((line) => line.y).reduce(math.min);
    for (final horizontalLine in chartModel.horizontalLines) {
      final point = LineChartMath.pointToOffset(
        chartModel,
        size,
        0,
        horizontalLine.y,
      );
      _drawStyledLine(
        canvas,
        horizontalLine.lineStyle,
        Offset(rect.left, point.dy),
        Offset(rect.right, point.dy),
      );

      final labelStyle = horizontalLine.labelStyle;
      if (!labelStyle.isVisible ||
          point.dy < rect.top ||
          point.dy > rect.bottom) {
        continue;
      }
      final text = _horizontalLineText(horizontalLine);
      final labelY = horizontalLine.y == minLineY
          ? lineLabelPositions.$1
          : lineLabelPositions.$2;
      switch (labelStyle.placement) {
        case AxisLabelPlacement.left:
          _drawText(
            canvas,
            text,
            Offset(rect.left + labelStyle.offset, labelY),
            _TextAnchor.maxXCenterY,
            labelStyle.textStyle,
            backgroundColor: labelStyle.color.withValues(alpha: 0.1),
            padding: padding,
            clampRect: rect,
          );
        case AxisLabelPlacement.right:
          _drawText(
            canvas,
            text,
            Offset(rect.right + labelStyle.offset, labelY),
            _TextAnchor.minXCenterY,
            labelStyle.textStyle,
            backgroundColor: labelStyle.color.withValues(alpha: 0.1),
            padding: padding,
            clampRect: rect,
          );
        case AxisLabelPlacement.top:
        case AxisLabelPlacement.bottom:
        case AxisLabelPlacement.none:
          break;
      }
    }

    canvas.save();
    canvas.clipRect(rect);
    for (final verticalLine in chartModel.verticalLines) {
      final x = LineChartMath.pointToOffset(
        chartModel,
        size,
        verticalLine.x,
        0,
      ).dx;
      _drawStyledLine(
        canvas,
        verticalLine.lineStyle,
        Offset(x, rect.top),
        Offset(x, rect.bottom),
      );
    }
    canvas.restore();
  }

  TextSpan _horizontalLineText(HorizontalLine line) {
    return horizontalLineTextFormatter?.call(line.y) ??
        TextSpan(
          text:
              horizontalLineFormatter?.call(line.y) ??
              line.y.toStringAsFixed(1),
        );
  }

  (double, double) _horizontalLinesMaxMinDrawY(
    Size size, {
    required EdgeInsets padding,
    required double distance,
  }) {
    final rect = LineChartMath.chartRect(chartModel, size);
    if (chartModel.horizontalLines.isEmpty) {
      return (0, 0);
    }
    final minLine = chartModel.horizontalLines.reduce(
      (current, line) => line.y < current.y ? line : current,
    );
    final maxLine = chartModel.horizontalLines.reduce(
      (current, line) => line.y > current.y ? line : current,
    );
    final minTextSize = LineChartMath.textSpanSize(
      _horizontalLineText(minLine),
      fallbackStyle: minLine.labelStyle.textStyle,
    );
    final maxTextSize = LineChartMath.textSpanSize(
      _horizontalLineText(maxLine),
      fallbackStyle: maxLine.labelStyle.textStyle,
    );
    final minHeight = minTextSize.height + padding.top + padding.bottom;
    final maxHeight = maxTextSize.height + padding.top + padding.bottom;
    final dataMinY = minLine.y;
    final dataMaxY = maxLine.y;
    var minY = LineChartMath.pointToOffset(chartModel, size, 0, dataMinY).dy;
    var maxY = LineChartMath.pointToOffset(chartModel, size, 0, dataMaxY).dy;
    final minAllowed = rect.top + maxHeight * 0.5;
    final maxAllowed = rect.bottom - minHeight * 0.5;
    final requiredDistance = maxHeight * 0.5 + minHeight * 0.5 + distance;

    maxY = math.max(maxY, minAllowed);
    minY = math.min(minY, maxAllowed);
    if (minY - maxY < requiredDistance) {
      final center = (minY + maxY) * 0.5;
      maxY = center - requiredDistance * 0.5;
      minY = center + requiredDistance * 0.5;
      if (maxY < minAllowed) {
        final shift = minAllowed - maxY;
        maxY += shift;
        minY += shift;
      }
      if (minY > maxAllowed) {
        final shift = minY - maxAllowed;
        maxY -= shift;
        minY -= shift;
      }
    }
    return (minY, maxY);
  }

  void _drawSelectedItem(Canvas canvas, Size size) {
    final item = chartModel.tappedItem;
    if (item == null) {
      return;
    }

    final rect = LineChartMath.chartRect(chartModel, size);
    final point = LineChartMath.pointToOffset(chartModel, size, item.x, item.y);
    if (!rect.contains(point)) {
      return;
    }

    final rangeColor = _colorForY(item.y);
    if (item.dataType == ChartPointDataType.data) {
      final outerPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = rangeColor == null ? Colors.grey : Colors.white;
      canvas.drawCircle(point, 8, outerPaint);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = rangeColor ?? Colors.white;
      canvas.drawCircle(point, 7, fillPaint);

      final dashPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = rangeColor ?? Colors.grey;
      _drawDashedLine(
        canvas,
        Offset(point.dx, rect.top),
        Offset(point.dx, rect.bottom),
        dashPaint,
        const [6, 3],
      );
    }

    final detailStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      height: 1.15,
      letterSpacing: 0,
    );
    final text = item.dataType == ChartPointDataType.data
        ? _tappedItemText(item)
        : XYTextModel(
            yText: const TextSpan(text: 'GAP'),
            xText: TextSpan(
              text:
                  '${LineChartMath.formatDate(item.gapLeft, 'yyyy/MM/dd HH:mm')} ~ '
                  '${LineChartMath.formatDate(item.gapRight, 'yyyy/MM/dd HH:mm')}',
            ),
          );
    final lines = <TextSpan>[text.yText, text.xText];
    final detailSize = LineChartMath.detailTextSize(
      lines,
      fallbackStyle: detailStyle,
    );
    item.detailSize = detailSize;
    final detailCenter = LineChartMath.detailCenter(
      chartModel,
      size,
      item,
      detailSize,
    );
    _drawTooltip(canvas, detailCenter, detailSize);
    if (item.dataType == ChartPointDataType.data) {
      final ySize = LineChartMath.textSpanSize(
        text.yText,
        fallbackStyle: detailStyle,
      );
      final xSize = LineChartMath.textSpanSize(
        text.xText,
        fallbackStyle: detailStyle,
      );
      final contentTop = detailCenter.dy - (ySize.height + xSize.height) * 0.5;
      _drawText(
        canvas,
        text.yText,
        Offset(detailCenter.dx, contentTop + ySize.height * 0.5),
        _TextAnchor.center,
        detailStyle,
      );
      _drawText(
        canvas,
        text.xText,
        Offset(detailCenter.dx, contentTop + ySize.height + xSize.height * 0.5),
        _TextAnchor.center,
        detailStyle,
      );
    } else {
      _drawText(
        canvas,
        text.yText,
        detailCenter.translate(0, -8),
        _TextAnchor.center,
        detailStyle,
      );
      _drawText(
        canvas,
        text.xText,
        detailCenter.translate(0, 8),
        _TextAnchor.center,
        detailStyle,
      );
    }
  }

  XYTextModel _tappedItemText(ChartPointModel item) {
    final attributed = tappedItemTextFormatter?.call(item);
    if (attributed != null) {
      return attributed;
    }
    final strings = tappedItemFormatter?.call(item);
    if (strings != null && strings.isNotEmpty) {
      return XYTextModel(
        yText: TextSpan(text: strings.first),
        xText: TextSpan(text: strings.length > 1 ? strings.last : ''),
      );
    }
    return XYTextModel(
      yText: TextSpan(text: item.y.toStringAsFixed(1)),
      xText: TextSpan(
        text: LineChartMath.formatDate(item.x, 'yyyy/MM/dd HH:mm'),
      ),
    );
  }

  MaxMinTextModel _rightAxisDataMaxMinText(double min, double max) {
    final attributed = rightAxisDataMaxMinTextFormatter?.call(min, max);
    if (attributed != null) {
      return attributed;
    }
    final strings = rightAxisDataMaxMinFormatter?.call(min, max);
    if (strings != null) {
      return MaxMinTextModel(
        max: TextSpan(text: strings.max),
        min: TextSpan(text: strings.min),
      );
    }
    return MaxMinTextModel(
      max: TextSpan(text: max.toStringAsFixed(1)),
      min: TextSpan(text: min.toStringAsFixed(1)),
    );
  }

  Color? _colorForY(double y) {
    for (final range in chartModel.verticalColorRanges) {
      if (range.top > y && range.bottom <= y) {
        return range.color;
      }
    }
    return null;
  }

  void _drawTooltip(Canvas canvas, Offset center, Size size) {
    final rect = Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      paint,
    );
  }

  void _drawStyledLine(
    Canvas canvas,
    ChartLineStyle style,
    Offset start,
    Offset end,
  ) {
    if (style.kind == LineStrokeKind.none) {
      return;
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.width
      ..strokeCap = StrokeCap.square
      ..color = style.color;
    if (style.kind == LineStrokeKind.dashLine) {
      _drawDashedLine(canvas, start, end, paint, style.dashPattern);
    } else {
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    List<double> pattern,
  ) {
    if (pattern.isEmpty) {
      canvas.drawLine(start, end, paint);
      return;
    }
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) {
      return;
    }
    final direction = delta / distance;
    var drawn = 0.0;
    var patternIndex = 0;
    while (drawn < distance) {
      final length = pattern[patternIndex % pattern.length];
      final next = math.min(drawn + length, distance);
      if (patternIndex.isEven) {
        canvas.drawLine(
          start + direction * drawn,
          start + direction * next,
          paint,
        );
      }
      drawn = next;
      patternIndex += 1;
    }
  }

  Size _drawText(
    Canvas canvas,
    Object text,
    Offset point,
    _TextAnchor anchor,
    TextStyle style, {
    Color? backgroundColor,
    EdgeInsets padding = EdgeInsets.zero,
    double? cornerRadius,
    Rect? clampRect,
  }) {
    final textSpan = text is TextSpan
        ? TextSpan(style: style, children: <InlineSpan>[text])
        : TextSpan(text: text.toString(), style: style);
    final painter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    final backgroundSize = Size(
      painter.width + padding.left + padding.right,
      painter.height + padding.top + padding.bottom,
    );
    var origin = _originForAnchor(point, backgroundSize, anchor);
    if (clampRect != null) {
      if (origin.dy < clampRect.top) {
        origin = Offset(origin.dx, clampRect.top);
      }
      if (origin.dy + backgroundSize.height > clampRect.bottom) {
        origin = Offset(origin.dx, clampRect.bottom - backgroundSize.height);
      }
    }

    if (backgroundColor != null) {
      final rect = origin & backgroundSize;
      final radius = cornerRadius ?? backgroundSize.height * 0.5;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = backgroundColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        paint,
      );
    }

    painter.paint(canvas, origin.translate(padding.left, padding.top));
    return backgroundSize;
  }

  Offset _originForAnchor(Offset point, Size size, _TextAnchor anchor) {
    switch (anchor) {
      case _TextAnchor.minXMinY:
        return point;
      case _TextAnchor.maxXMinY:
        return Offset(point.dx - size.width, point.dy);
      case _TextAnchor.minXMaxY:
        return Offset(point.dx, point.dy - size.height);
      case _TextAnchor.maxXMaxY:
        return Offset(point.dx - size.width, point.dy - size.height);
      case _TextAnchor.centerXMinY:
        return Offset(point.dx - size.width * 0.5, point.dy);
      case _TextAnchor.minXCenterY:
        return Offset(point.dx, point.dy - size.height * 0.5);
      case _TextAnchor.maxXCenterY:
        return Offset(point.dx - size.width, point.dy - size.height * 0.5);
      case _TextAnchor.centerXMaxY:
        return Offset(point.dx - size.width * 0.5, point.dy - size.height);
      case _TextAnchor.center:
        return Offset(
          point.dx - size.width * 0.5,
          point.dy - size.height * 0.5,
        );
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => true;
}
