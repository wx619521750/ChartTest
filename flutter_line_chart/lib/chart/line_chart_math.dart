import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'line_chart_models.dart';

enum TimeIntervalStepUnit { minutes, hours, days, months }

class TimeIntervalStep {
  const TimeIntervalStep._(this.unit, this.value);

  const TimeIntervalStep.minutes(int value)
    : this._(TimeIntervalStepUnit.minutes, value);

  const TimeIntervalStep.hours(int value)
    : this._(TimeIntervalStepUnit.hours, value);

  const TimeIntervalStep.days(int value)
    : this._(TimeIntervalStepUnit.days, value);

  const TimeIntervalStep.months(int value)
    : this._(TimeIntervalStepUnit.months, value);

  final TimeIntervalStepUnit unit;
  final int value;
}

class DateTicks {
  const DateTicks({required this.stamps, required this.format});

  final List<double> stamps;
  final String format;
}

class LineChartMath {
  static Rect chartRect(ChartModel model, Size size) {
    final inset = model.chartContentInset;
    return Rect.fromLTRB(
      inset.left,
      inset.top,
      size.width - inset.right,
      size.height - inset.bottom,
    );
  }

  static Offset pointToOffset(ChartModel model, Size size, double x, double y) {
    final rect = chartRect(model, size);
    final xRange = model.maxX - model.minX;
    final yRange = model.maxY - model.minY;
    if (xRange == 0 || yRange == 0 || rect.width <= 0 || rect.height <= 0) {
      return rect.center;
    }
    final dx = rect.left + (x - model.minX) / xRange * rect.width;
    final dy = rect.bottom - (y - model.minY) / yRange * rect.height;
    return Offset(dx, dy);
  }

  static Offset dataPointFromOffset(ChartModel model, Size size, Offset point) {
    final rect = chartRect(model, size);
    final xRange = model.maxX - model.minX;
    final yRange = model.maxY - model.minY;
    if (rect.width <= 0 || rect.height <= 0) {
      return Offset(model.minX, model.minY);
    }
    final x = model.minX + (point.dx - rect.left) / rect.width * xRange;
    final y = model.minY + (rect.bottom - point.dy) / rect.height * yRange;
    return Offset(x, y);
  }

  static List<ChartPointModel> visibleData(ChartModel model) {
    final points = model.lineModel.points;
    if (points.isEmpty) {
      return <ChartPointModel>[];
    }

    ChartPointModel? leftData;
    ChartPointModel? rightData;
    for (final point in points) {
      if (point.x <= model.minX) {
        leftData = point;
      }
      if (rightData == null && point.x >= model.maxX) {
        rightData = point;
      }
    }

    if (leftData != null && rightData != null) {
      return points
          .where((point) => point.x >= leftData!.x && point.x <= rightData!.x)
          .toList();
    }
    if (leftData != null) {
      return points.where((point) => point.x >= leftData!.x).toList();
    }
    if (rightData != null) {
      return points.where((point) => point.x <= rightData!.x).toList();
    }
    return List<ChartPointModel>.of(points);
  }

  static void updateYRange(ChartModel model, List<ChartPointModel> visible) {
    switch (model.yRangeType.mode) {
      case YRangeMode.selfAdaptAll:
        final ys = model.lineModel.points.map((point) => point.y).toList();
        model.minY = ys.isEmpty ? 0 : ys.reduce(math.min);
        model.maxY = ys.isEmpty ? 0 : ys.reduce(math.max);
      case YRangeMode.selfAdaptVisible:
        final ys = visible.map((point) => point.y).toList();
        model.minY = ys.isEmpty ? 0 : ys.reduce(math.min);
        model.maxY = ys.isEmpty ? 0 : ys.reduce(math.max);
      case YRangeMode.selfAdaptVisibleWithType:
        final ys = visible.map((point) => point.y).toList();
        final minY = ys.isEmpty ? 0.0 : ys.reduce(math.min);
        final maxY = ys.isEmpty ? 0.0 : ys.reduce(math.max);
        final distance = maxY - minY;
        var padding = distance * 0.3;
        if (padding < 0.2) {
          padding = 0.2;
        }
        if (padding > 2) {
          padding = 2;
        }
        model.minY = minY - padding;
        model.maxY = maxY + padding;
        if (model.yRangeType.chartType == XSChartType.humidity) {
          model.minY = model.minY < 0 ? 0 : model.minY;
          model.maxY = model.maxY > 100 ? 100 : model.maxY;
        }
      case YRangeMode.selfAdaptVisibleWithMinMax:
        final ys = visible.map((point) => point.y).toList();
        final dataMin = ys.isEmpty ? 0.0 : ys.reduce(math.min);
        final dataMax = ys.isEmpty ? 0.0 : ys.reduce(math.max);
        final minLimit = model.yRangeType.min ?? dataMin;
        final maxLimit = model.yRangeType.max ?? dataMax;
        model.minY = minLimit < dataMin ? minLimit : dataMin;
        model.maxY = maxLimit > dataMax ? maxLimit : dataMax;
      case YRangeMode.fixed:
        model.minY = model.yRangeType.min ?? 0;
        model.maxY = model.yRangeType.max ?? 0;
    }

    if (model.minY == model.maxY) {
      model.minY -= 0.5;
      model.maxY += 0.5;
    }
  }

  static List<HorizontalEmptyAreaModel> filterPointsByXDistance(
    List<ChartPointModel> points, {
    double threshold = 7200,
  }) {
    if (points.length <= 1) {
      return <HorizontalEmptyAreaModel>[];
    }
    final result = <HorizontalEmptyAreaModel>[];
    for (var index = 0; index < points.length - 1; index += 1) {
      final currentPoint = points[index];
      final nextPoint = points[index + 1];
      if (nextPoint.dataType != ChartPointDataType.data) {
        continue;
      }
      if (nextPoint.x - currentPoint.x > threshold) {
        result.add(
          HorizontalEmptyAreaModel(left: currentPoint.x, right: nextPoint.x),
        );
      }
    }
    return result;
  }

  static List<ChartPointModel> resampleLTTB({
    required List<ChartPointModel> data,
    required int threshold,
    ChartPointModel? selected,
  }) {
    if (threshold >= data.length || data.length <= 2) {
      return List<ChartPointModel>.of(data);
    }

    final bucketSize = (data.length - 2) / (threshold - 2);
    final result = <ChartPointModel>[data.first];
    var anchorIndex = 0;

    for (var bucket = 0; bucket < threshold - 2; bucket += 1) {
      final rangeStart = (bucket + 1) * bucketSize ~/ 1 + 1;
      final rangeEnd = (bucket + 2) * bucketSize ~/ 1 + 1;
      final nextStart = (bucket + 2) * bucketSize ~/ 1 + 1;
      final nextEnd = (bucket + 3) * bucketSize ~/ 1 + 1;
      final avgStart = nextStart.clamp(0, data.length).toInt();
      final avgEnd = nextEnd.clamp(avgStart + 1, data.length).toInt();
      final avgSlice = data.sublist(avgStart, avgEnd);
      final avgX =
          avgSlice.map((point) => point.x).reduce((a, b) => a + b) /
          avgSlice.length;
      final avgY =
          avgSlice.map((point) => point.y).reduce((a, b) => a + b) /
          avgSlice.length;

      var maxArea = -1.0;
      var selectedPoint = data[rangeStart.clamp(0, data.length - 1).toInt()];
      final end = rangeEnd.clamp(rangeStart + 1, data.length).toInt();

      for (var index = rangeStart; index < end; index += 1) {
        final candidate = data[index];
        final anchor = data[anchorIndex];
        final area =
            ((anchor.x - avgX) * (candidate.y - anchor.y) -
                    (anchor.x - candidate.x) * (avgY - anchor.y))
                .abs();
        if (area > maxArea) {
          maxArea = area;
          selectedPoint = candidate;
        }
        if (selected != null &&
            candidate.dataType == selected.dataType &&
            candidate.x == selected.x) {
          result.add(candidate);
        }
        if (candidate.dataType == ChartPointDataType.gap) {
          result.add(candidate);
        }
      }

      result.add(selectedPoint);
      anchorIndex = data.indexWhere(
        (point) => point.x == selectedPoint.x && point.y == selectedPoint.y,
      );
      if (anchorIndex < 0) {
        anchorIndex = 0;
      }
    }

    result.add(data.last);
    return _uniqueByXType(result)..sort((a, b) => a.x.compareTo(b.x));
  }

  static List<ChartPointModel> _uniqueByXType(List<ChartPointModel> points) {
    final seen = <String>{};
    final result = <ChartPointModel>[];
    for (final point in points) {
      final key = '${point.dataType.name}:${point.x}:${point.y}';
      if (seen.add(key)) {
        result.add(point);
      }
    }
    return result;
  }

  static List<double> generateAxisSteps({
    required double min,
    required double max,
    required AxisStepType type,
  }) {
    if (min >= max) {
      return <double>[];
    }

    switch (type.kind) {
      case AxisStepKind.distance:
        final distance = type.distance;
        if (distance <= 0) {
          return <double>[];
        }
        final align = type.align;
        final result = <double>[];
        if (align != null) {
          var current = (min / align).ceil() * align;
          while (current <= max) {
            final remainder = current % align;
            if (current >= min &&
                current <= max &&
                (remainder.abs() < 0.0001 ||
                    (remainder - align).abs() < 0.0001)) {
              result.add(current);
            }
            current += distance;
            if (current > max + distance) {
              break;
            }
          }
        } else {
          var current = min;
          while (current <= max + 0.0001) {
            result.add(current);
            current += distance;
            if (result.length > 10000) {
              break;
            }
          }
        }
        return result;
      case AxisStepKind.separateCount:
        final count = type.count;
        if (count < 2) {
          return <double>[min, max];
        }
        final step = (max - min) / (count - 1);
        return List<double>.generate(count, (index) => min + step * index);
      case AxisStepKind.dateAdapt:
      case AxisStepKind.none:
        return <double>[];
    }
  }

  static DateTicks getDateAdaptStamps(ChartModel model, Size size) {
    final range = model.maxX - model.minX;
    var dateFormat = 'HH:mm';
    late final TimeIntervalStep step;
    if (range <= 1800) {
      step = const TimeIntervalStep.minutes(5);
    } else if (range <= 3600) {
      step = const TimeIntervalStep.minutes(10);
    } else if (range <= 3600 * 6) {
      step = const TimeIntervalStep.hours(1);
    } else if (range <= 3600 * 12) {
      step = const TimeIntervalStep.hours(2);
    } else if (range <= 3600 * 24) {
      step = const TimeIntervalStep.hours(4);
    } else if (range <= 3600 * 24 * 7) {
      step = const TimeIntervalStep.days(1);
      dateFormat = 'EEE';
    } else if (range <= 3600 * 24 * 14) {
      step = const TimeIntervalStep.days(2);
      dateFormat = 'MM/dd';
    } else if (range <= 3600 * 24 * 30) {
      step = const TimeIntervalStep.days(5);
      dateFormat = 'MM/dd';
    } else if (range <= 3600 * 24 * 30 * 6) {
      step = const TimeIntervalStep.months(1);
      dateFormat = 'MMM';
    } else if (range <= 3600 * 24 * 30 * 12) {
      step = const TimeIntervalStep.months(2);
      dateFormat = 'MMM';
    } else {
      final count = math.max(1, (range / 6 / (3600 * 24 * 30)).round());
      step = TimeIntervalStep.months(count);
      dateFormat = 'MMM';
    }

    return DateTicks(
      stamps: alignedTimestamps(model: model, size: size, step: step),
      format: dateFormat,
    );
  }

  static List<double> alignedTimestamps({
    required ChartModel model,
    required Size size,
    required TimeIntervalStep step,
  }) {
    if (model.minX >= model.maxX) {
      return <double>[];
    }

    final rect = chartRect(model, size);
    var start = model.minX;
    var end = model.maxX;
    if (model.horizontalAxisFullFrame && rect.width > 0) {
      start =
          model.minX -
          (model.maxX - model.minX) / rect.width * model.chartContentInset.left;
      end =
          model.maxX +
          (model.maxX - model.minX) /
              rect.width *
              model.chartContentInset.right;
    }

    var current = _alignedDate(
      DateTime.fromMillisecondsSinceEpoch((start * 1000).round()),
      step,
    );
    final startDate = DateTime.fromMillisecondsSinceEpoch(
      (start * 1000).round(),
    );
    final endDate = DateTime.fromMillisecondsSinceEpoch((end * 1000).round());
    while (current.isBefore(startDate)) {
      current = _addStep(current, step);
    }

    final result = <double>[];
    while (!current.isAfter(endDate)) {
      result.add(current.millisecondsSinceEpoch / 1000);
      current = _addStep(current, step);
    }
    return result;
  }

  static DateTime _alignedDate(DateTime date, TimeIntervalStep step) {
    switch (step.unit) {
      case TimeIntervalStepUnit.minutes:
        final minute = date.minute;
        final remainder = minute % step.value;
        final alignedMinute = remainder == 0
            ? minute
            : minute + (step.value - remainder);
        return DateTime(
          date.year,
          date.month,
          date.day,
          date.hour,
          alignedMinute,
        );
      case TimeIntervalStepUnit.hours:
        final hour = date.hour;
        final remainder = hour % step.value;
        final alignedHour = remainder == 0
            ? hour
            : hour + (step.value - remainder);
        return DateTime(date.year, date.month, date.day, alignedHour);
      case TimeIntervalStepUnit.days:
        final day = date.day;
        final remainder = (day - 1) % step.value;
        final alignedDay = remainder == 0
            ? day
            : day + (step.value - remainder);
        return DateTime(date.year, date.month, alignedDay);
      case TimeIntervalStepUnit.months:
        final month = date.month;
        final remainder = (month - 1) % step.value;
        final alignedMonth = remainder == 0
            ? month
            : month + (step.value - remainder);
        return DateTime(date.year, alignedMonth);
    }
  }

  static DateTime _addStep(DateTime date, TimeIntervalStep step) {
    switch (step.unit) {
      case TimeIntervalStepUnit.minutes:
        return date.add(Duration(minutes: step.value));
      case TimeIntervalStepUnit.hours:
        return date.add(Duration(hours: step.value));
      case TimeIntervalStepUnit.days:
        return date.add(Duration(days: step.value));
      case TimeIntervalStepUnit.months:
        return DateTime(date.year, date.month + step.value, date.day);
    }
  }

  static String formatDate(double seconds, String format) {
    final date = DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round());
    String two(int value) => value.toString().padLeft(2, '0');
    switch (format) {
      case 'HH:mm':
        return '${two(date.hour)}:${two(date.minute)}';
      case 'EEE':
        const weekdays = <String>[
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ];
        return weekdays[date.weekday - 1];
      case 'MM/dd':
        return '${two(date.month)}/${two(date.day)}';
      case 'MMM':
        const months = <String>[
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return months[date.month - 1];
      case 'yyyy-MM-dd HH:mm:ss':
        return '${date.year}-${two(date.month)}-${two(date.day)} '
            '${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
      case 'yyyy/MM/dd HH:mm':
        return '${date.year}/${two(date.month)}/${two(date.day)} '
            '${two(date.hour)}:${two(date.minute)}';
      default:
        return '${date.year}-${two(date.month)}-${two(date.day)}';
    }
  }

  static Size textSize(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.size;
  }

  static Size detailSize(List<String> lines, TextStyle style) {
    var width = 0.0;
    var height = 0.0;
    for (final line in lines) {
      final size = textSize(line, style);
      width = math.max(width, size.width);
      height += size.height;
    }
    return Size(width + 12, height + 12);
  }

  static Offset detailCenter(
    ChartModel model,
    Size size,
    ChartPointModel item,
    Size detailSize,
  ) {
    final rect = chartRect(model, size);
    final point = pointToOffset(model, size, item.x, item.y);
    const yOffset = 10.0;
    var x = point.dx;
    var y = point.dy + detailSize.height * 0.5 + yOffset;
    if (x - detailSize.width * 0.5 < rect.left) {
      x = detailSize.width * 0.5 + rect.left;
    }
    if (x + detailSize.width * 0.5 > rect.right) {
      x = rect.right - detailSize.width * 0.5;
    }
    if (y + detailSize.height * 0.5 > rect.bottom) {
      y = point.dy - detailSize.height * 0.5 - yOffset;
    }
    return Offset(x, y);
  }
}
