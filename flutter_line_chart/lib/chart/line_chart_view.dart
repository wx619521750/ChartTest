import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'line_chart_math.dart';
import 'line_chart_models.dart';
import 'line_chart_painter.dart';

typedef ChartDateModeChanged =
    void Function(FlutterLineChartViewState chartView, DateMode mode);
typedef ChartRangeChanged =
    void Function(FlutterLineChartViewState chartView, double min, double max);
typedef ChartHorizontalLineTextFormatter =
    TextSpan Function(FlutterLineChartViewState chartView, double y);
typedef ChartTappedItemTextFormatter =
    XYTextModel Function(
      FlutterLineChartViewState chartView,
      double x,
      double y,
    );
typedef ChartRightAxisDataMaxMinTextFormatter =
    MaxMinTextModel Function(
      FlutterLineChartViewState chartView,
      double min,
      double max,
    );
typedef ChartAxisGraduationTextFormatter =
    TextSpan? Function(
      FlutterLineChartViewState chartView,
      AxisLabelPlacement direction,
      double value,
    );
typedef ChartBottomAxisMaxMinTextFormatter =
    TextSpan Function(FlutterLineChartViewState chartView, double x);

class FlutterLineChartView extends StatefulWidget {
  const FlutterLineChartView({
    super.key,
    required this.model,
    this.height = 240,
    this.onDateModeChanged,
    this.onDateModeChangedWithChart,
    this.onXRangeChanged,
    this.onXRangeChangedWithChart,
    this.onXRangeChangedByUserInteraction,
    this.onYRangeChanged,
    this.onYRangeChangedWithChart,
    this.horizontalLineFormatter,
    this.horizontalLineTextFormatter,
    this.tappedItemFormatter,
    this.tappedItemTextFormatter,
    this.rightAxisDataMaxMinFormatter,
    this.rightAxisDataMaxMinTextFormatter,
    this.axisGraduationFormatter,
    this.axisGraduationTextFormatter,
    this.bottomAxisMaxMinFormatter,
    this.bottomAxisMaxMinTextFormatter,
  });

  final ChartModel model;
  final double height;
  final ValueChanged<DateMode>? onDateModeChanged;
  final ChartDateModeChanged? onDateModeChangedWithChart;
  final void Function(double min, double max)? onXRangeChanged;
  final ChartRangeChanged? onXRangeChangedWithChart;
  final ChartRangeChanged? onXRangeChangedByUserInteraction;
  final void Function(double min, double max)? onYRangeChanged;
  final ChartRangeChanged? onYRangeChangedWithChart;
  final HorizontalLineFormatter? horizontalLineFormatter;
  final ChartHorizontalLineTextFormatter? horizontalLineTextFormatter;
  final TappedItemFormatter? tappedItemFormatter;
  final ChartTappedItemTextFormatter? tappedItemTextFormatter;
  final RightAxisDataMaxMinFormatter? rightAxisDataMaxMinFormatter;
  final ChartRightAxisDataMaxMinTextFormatter? rightAxisDataMaxMinTextFormatter;
  final AxisGraduationFormatter? axisGraduationFormatter;
  final ChartAxisGraduationTextFormatter? axisGraduationTextFormatter;
  final BottomAxisMaxMinFormatter? bottomAxisMaxMinFormatter;
  final ChartBottomAxisMaxMinTextFormatter? bottomAxisMaxMinTextFormatter;

  @override
  FlutterLineChartViewState createState() => FlutterLineChartViewState();
}

class FlutterLineChartViewState extends State<FlutterLineChartView>
    with SingleTickerProviderStateMixin {
  late ChartModel _chartModel;
  late EdgeInsets _sourceChartContentInset;
  Size _chartSize = Size.zero;
  Offset _pinchLocation = Offset.zero;
  double _tempMinX = 0;
  double _tempMaxX = 0;
  bool _isLabelPanning = false;
  bool? _isHorizontalGesture;
  bool _didPinch = false;
  final Map<int, VelocityTracker> _velocityTrackers = <int, VelocityTracker>{};
  final Set<int> _activePointers = <int>{};
  double _trackedVelocityX = 0;
  late final Ticker _decelerationTicker;
  double _decelerationVelocityX = 0;
  Duration? _lastDecelerationElapsed;

  static const double _decelerationStartVelocityThreshold = 120;
  static const double _decelerationStopVelocityThreshold = 5;

  ChartModel get chartModel => _chartModel;

  @override
  void initState() {
    super.initState();
    _decelerationTicker = createTicker(_handleDecelerationTick);
    _chartModel = widget.model.copy();
    _sourceChartContentInset = widget.model.chartContentInset;
    _dealData();
  }

  @override
  void didUpdateWidget(covariant FlutterLineChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.model, widget.model)) {
      _stopDeceleration();
      _chartModel = widget.model.copy();
      _sourceChartContentInset = widget.model.chartContentInset;
      _dealData();
    } else if (_sourceChartContentInset != widget.model.chartContentInset) {
      _sourceChartContentInset = widget.model.chartContentInset;
      _chartModel.chartContentInset = widget.model.chartContentInset;
    }
  }

  @override
  void dispose() {
    _stopDeceleration();
    _decelerationTicker.dispose();
    super.dispose();
  }

  void changeDateMode(DateMode mode) {
    _stopDeceleration();
    _chartModel.dateMode = mode;
    _applyDateMode(mode);
    setState(() => _dealModels(notifyYRange: false));
    _notifyDateModeChanged();
    _notifyXRangeChanged();
    _notifyYRangeChanged();
  }

  void changeXRange({required double min, required double max}) {
    _stopDeceleration();
    _changeXRange(min: min, max: max);
  }

  void _dealData() {
    final xs = _chartModel.lineModel.points.map((point) => point.x).toList();
    final now = DateTime.now().millisecondsSinceEpoch / 1000;
    _chartModel.minX = xs.isEmpty ? now : xs.reduce(math.min);
    _chartModel.maxX = xs.isEmpty ? now : xs.reduce(math.max);
    _chartModel.lineModel.points.sort((a, b) => a.x.compareTo(b.x));
    _applyDateMode(_chartModel.dateMode);
    _dealModels(notifyYRange: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _notifyDateModeChanged();
      _notifyXRangeChanged();
      _notifyYRangeChanged();
    });
  }

  void _dealModels({bool notifyYRange = true}) {
    final visible = LineChartMath.visibleData(_chartModel);
    LineChartMath.updateYRange(_chartModel, visible);
    _chartModel.lineModel.emptyAreas = LineChartMath.filterPointsByXDistance(
      visible,
    );
    _chartModel.lineModel.pointsShouldDraw = LineChartMath.resampleLTTB(
      data: visible,
      threshold: 200,
      selected: _chartModel.tappedItem,
    );
    _addGapModels();
    if (notifyYRange) {
      _notifyYRangeChanged();
    }
  }

  void _addGapModels() {
    for (final area in _chartModel.lineModel.emptyAreas) {
      _chartModel.lineModel.pointsShouldDraw.add(
        ChartPointModel(
          dataType: ChartPointDataType.gap,
          x: (area.left + area.right) * 0.5,
          y: _chartModel.maxY,
          gapLeft: area.left,
          gapRight: area.right,
        ),
      );
    }
    _chartModel.lineModel.pointsShouldDraw.sort((a, b) => a.x.compareTo(b.x));
  }

  void _applyDateMode(DateMode mode) {
    _chartModel.minX = _chartModel.maxX - mode.duration.inSeconds.toDouble();
  }

  void _changeXRange({
    required double min,
    required double max,
    bool autoDateMode = true,
    bool isUserInteraction = false,
  }) {
    final bounded = _boundedXRange(min, max);
    setState(() {
      _chartModel.minX = bounded.$1;
      _chartModel.maxX = bounded.$2;
      _dealModels(notifyYRange: false);
      if (autoDateMode) {
        _autoChangeDateMode();
      }
    });
    _notifyXRangeChanged(isUserInteraction: isUserInteraction);
    _notifyYRangeChanged();
  }

  (double, double) _boundedXRange(double min, double max) {
    return LineChartMath.boundXRange(
      min: min,
      max: max,
      rangeType: _chartModel.xRangeType,
      points: _chartModel.lineModel.points,
    );
  }

  void _autoChangeDateMode() {
    final range = _chartModel.maxX - _chartModel.minX;
    final oldMode = _chartModel.dateMode;
    if (range <= 3600 * 24) {
      _chartModel.dateMode = DateMode.day;
    } else if (range <= 3600 * 24 * 7) {
      _chartModel.dateMode = DateMode.week;
    } else if (range <= 3600 * 24 * 30) {
      _chartModel.dateMode = DateMode.month;
    } else if (range <= 3600 * 24 * 30 * 12) {
      _chartModel.dateMode = DateMode.year;
    }
    if (oldMode != _chartModel.dateMode) {
      _notifyDateModeChanged();
    }
  }

  void _notifyDateModeChanged() {
    widget.onDateModeChanged?.call(_chartModel.dateMode);
    widget.onDateModeChangedWithChart?.call(this, _chartModel.dateMode);
  }

  void _notifyXRangeChanged({bool isUserInteraction = false}) {
    widget.onXRangeChanged?.call(_chartModel.minX, _chartModel.maxX);
    widget.onXRangeChangedWithChart?.call(
      this,
      _chartModel.minX,
      _chartModel.maxX,
    );
    if (isUserInteraction) {
      widget.onXRangeChangedByUserInteraction?.call(
        this,
        _chartModel.minX,
        _chartModel.maxX,
      );
    }
  }

  void _notifyYRangeChanged() {
    widget.onYRangeChanged?.call(_chartModel.minY, _chartModel.maxY);
    widget.onYRangeChangedWithChart?.call(
      this,
      _chartModel.minY,
      _chartModel.maxY,
    );
  }

  void _handleTapUp(TapUpDetails details) {
    final existingItem = _chartModel.tappedItem;
    if (existingItem != null) {
      final tooltipRect = _tooltipRectFor(existingItem);
      if (tooltipRect?.contains(details.localPosition) ?? false) {
        setState(() => _chartModel.tappedItem = null);
        return;
      }
    }
    _selectNearestAt(details.localPosition);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _stopDeceleration();
    if (_activePointers.isEmpty) {
      _trackedVelocityX = 0;
    }
    _activePointers.add(event.pointer);
    _velocityTrackers[event.pointer] = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final tracker = _velocityTrackers[event.pointer];
    if (tracker == null || event.synthesized) {
      return;
    }
    tracker.addPosition(event.timeStamp, event.position);
    if (_activePointers.length == 1) {
      final velocityX = tracker.getVelocity().pixelsPerSecond.dx;
      if (velocityX.isFinite) {
        _trackedVelocityX = velocityX;
      }
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final tracker = _velocityTrackers[event.pointer];
    if (tracker != null) {
      tracker.addPosition(event.timeStamp, event.position);
      if (_activePointers.length == 1) {
        final velocityX = tracker.getVelocity().pixelsPerSecond.dx;
        if (velocityX.isFinite) {
          _trackedVelocityX = velocityX;
        }
      }
    }
    _activePointers.remove(event.pointer);
    _velocityTrackers.remove(event.pointer);
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    _velocityTrackers.remove(event.pointer);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _stopDeceleration();
    _isHorizontalGesture = null;
    _didPinch = details.pointerCount >= 2;
    _pinchLocation = details.localFocalPoint;
    _tempMinX = _chartModel.minX;
    _tempMaxX = _chartModel.maxX;
    final existingItem = _chartModel.tappedItem;
    _isLabelPanning = false;
    if (existingItem != null) {
      final tooltipRect = _tooltipRectFor(existingItem);
      _isLabelPanning = tooltipRect?.contains(details.localFocalPoint) ?? false;
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final isPinching =
        details.pointerCount >= 2 || (details.scale - 1).abs() > 0.01;
    if (isPinching) {
      _didPinch = true;
      _handlePinchUpdate(details);
      return;
    }

    final delta = details.focalPointDelta;
    if (_isHorizontalGesture == null && delta.distance > 1) {
      _isHorizontalGesture = delta.dx.abs() > delta.dy.abs();
    }
    if (_isHorizontalGesture != true) {
      return;
    }
    if (_isLabelPanning) {
      _selectNearestAt(details.localFocalPoint);
      return;
    }
    final dataOffset = _dataOffsetFromViewTranslation(delta.dx);
    _shiftVisibleRange(by: dataOffset);
  }

  void _handlePinchUpdate(ScaleUpdateDetails details) {
    if (_chartSize.width <= 0 || details.scale == 0) {
      return;
    }
    final rect = LineChartMath.chartRect(_chartModel, _chartSize);
    if (rect.width <= 0) {
      return;
    }
    final locationX =
        (_pinchLocation.dx - rect.left) / rect.width * (_tempMaxX - _tempMinX) +
        _tempMinX;
    var newMinX = locationX - (locationX - _tempMinX) * (1 / details.scale);
    var newMaxX = locationX + (_tempMaxX - locationX) * (1 / details.scale);
    if (newMaxX - newMinX < 3600) {
      final center = (_chartModel.maxX + _chartModel.minX) * 0.5;
      newMinX = center - 1800;
      newMaxX = center + 1800;
    }
    _changeXRange(min: newMinX, max: newMaxX, isUserInteraction: true);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_isLabelPanning || _didPinch) {
      _isLabelPanning = false;
      _didPinch = false;
      return;
    }
    _isLabelPanning = false;
    final gestureVelocityX = details.velocity.pixelsPerSecond.dx;
    final velocityX = gestureVelocityX.abs() > _trackedVelocityX.abs()
        ? gestureVelocityX
        : _trackedVelocityX;
    _startDeceleration(velocityX);
  }

  void _selectNearestAt(Offset localPosition) {
    if (_chartSize == Size.zero) {
      return;
    }
    final dataPoint = LineChartMath.dataPointFromOffset(
      _chartModel,
      _chartSize,
      localPosition,
    );
    final item = _nearestItem(
      _chartModel.lineModel.pointsShouldDraw,
      dataPoint.dx,
    );
    setState(() {
      _chartModel.tappedItem = item?.copy();
      _dealModels(notifyYRange: false);
    });
  }

  ChartPointModel? _nearestItem(List<ChartPointModel> items, double x) {
    final dataItems = items
        .where((item) => item.dataType == ChartPointDataType.data)
        .toList();
    if (dataItems.isEmpty) {
      return null;
    }
    dataItems.sort((a, b) => (a.x - x).abs().compareTo((b.x - x).abs()));
    return dataItems.first;
  }

  double _dataOffsetFromViewTranslation(double translationX) {
    if (_chartSize.width <= 0) {
      return 0;
    }
    return translationX /
        _chartSize.width *
        (_chartModel.maxX - _chartModel.minX);
  }

  bool _shiftVisibleRange({required double by}) {
    final newMinX = _chartModel.minX - by;
    final newMaxX = _chartModel.maxX - by;

    switch (_chartModel.xRangeType.mode) {
      case XRangeMode.unlimited:
        _changeXRange(min: newMinX, max: newMaxX, isUserInteraction: true);
        return true;
      case XRangeMode.limitedByData:
        final points = _chartModel.lineModel.points;
        if (points.isNotEmpty && newMinX < points.first.x) {
          final distance = points.first.x - _chartModel.minX;
          if (distance != 0) {
            _changeXRange(
              min: _chartModel.minX + distance,
              max: _chartModel.maxX + distance,
              isUserInteraction: true,
            );
          }
          return false;
        }
        if (points.isNotEmpty && newMaxX > points.last.x) {
          final distance = points.last.x - _chartModel.maxX;
          if (distance != 0) {
            _changeXRange(
              min: _chartModel.minX + distance,
              max: _chartModel.maxX + distance,
              isUserInteraction: true,
            );
          }
          return false;
        }
        _changeXRange(min: newMinX, max: newMaxX, isUserInteraction: true);
        return true;
      case XRangeMode.distanceByNow:
        final now = DateTime.now().millisecondsSinceEpoch / 1000;
        final lowerBound = now - _chartModel.xRangeType.distanceByNow;
        if (newMinX < lowerBound) {
          final distance = lowerBound - _chartModel.minX;
          if (distance != 0) {
            _changeXRange(
              min: _chartModel.minX + distance,
              max: _chartModel.maxX + distance,
              isUserInteraction: true,
            );
          }
          return false;
        }
        if (newMaxX > now) {
          final distance = now - _chartModel.maxX;
          if (distance != 0) {
            _changeXRange(
              min: _chartModel.minX + distance,
              max: _chartModel.maxX + distance,
              isUserInteraction: true,
            );
          }
          return false;
        }
        _changeXRange(min: newMinX, max: newMaxX, isUserInteraction: true);
        return true;
    }
  }

  void _startDeceleration(double velocityX) {
    _stopDeceleration();
    if (!_chartModel.enableDeceleration ||
        velocityX.abs() <= _decelerationStartVelocityThreshold) {
      return;
    }
    _decelerationVelocityX = velocityX;
    _lastDecelerationElapsed = null;
    _decelerationTicker.start();
  }

  void _stopDeceleration() {
    if (_decelerationTicker.isActive) {
      _decelerationTicker.stop();
    }
    _decelerationVelocityX = 0;
    _lastDecelerationElapsed = null;
  }

  void _handleDecelerationTick(Duration elapsed) {
    final previous = _lastDecelerationElapsed;
    _lastDecelerationElapsed = elapsed;
    if (previous == null) {
      return;
    }

    final deltaTime = (elapsed - previous).inMicroseconds / 1000000;
    final didMove = _shiftVisibleRange(
      by: _dataOffsetFromViewTranslation(_decelerationVelocityX * deltaTime),
    );
    final rate = math.pow(0.998, deltaTime * 1000).toDouble();
    _decelerationVelocityX *= rate;
    if (!didMove ||
        _decelerationVelocityX.abs() < _decelerationStopVelocityThreshold) {
      _stopDeceleration();
    }
  }

  Rect? _tooltipRectFor(ChartPointModel item) {
    if (_chartSize == Size.zero) {
      return null;
    }
    const detailStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      height: 1.15,
      letterSpacing: 0,
    );
    final text = _detailText(item);
    final detailSize = LineChartMath.detailTextSize(<TextSpan>[
      text.yText,
      text.xText,
    ], fallbackStyle: detailStyle);
    item.detailSize = detailSize;
    final center = LineChartMath.detailCenter(
      _chartModel,
      _chartSize,
      item,
      detailSize,
    );
    return Rect.fromCenter(
      center: center,
      width: detailSize.width,
      height: detailSize.height,
    );
  }

  TextSpan _horizontalLineTextFormatter(double y) {
    return widget.horizontalLineTextFormatter?.call(this, y) ??
        TextSpan(
          text: widget.horizontalLineFormatter?.call(y) ?? y.toStringAsFixed(1),
        );
  }

  XYTextModel _tappedItemTextFormatter(ChartPointModel item) {
    final attributed = widget.tappedItemTextFormatter?.call(
      this,
      item.x,
      item.y,
    );
    if (attributed != null) {
      return attributed;
    }
    final strings = widget.tappedItemFormatter?.call(item);
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

  XYTextModel _detailText(ChartPointModel item) {
    if (item.dataType == ChartPointDataType.data) {
      return _tappedItemTextFormatter(item);
    }
    return XYTextModel(
      yText: const TextSpan(text: 'GAP'),
      xText: TextSpan(
        text:
            '${LineChartMath.formatDate(item.gapLeft, 'yyyy/MM/dd HH:mm')} ~ '
            '${LineChartMath.formatDate(item.gapRight, 'yyyy/MM/dd HH:mm')}',
      ),
    );
  }

  MaxMinTextModel _rightAxisDataMaxMinTextFormatter(double min, double max) {
    final attributed = widget.rightAxisDataMaxMinTextFormatter?.call(
      this,
      min,
      max,
    );
    if (attributed != null) {
      return attributed;
    }
    final strings = widget.rightAxisDataMaxMinFormatter?.call(min, max);
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

  TextSpan? _axisGraduationTextFormatter(
    AxisLabelPlacement direction,
    double value,
  ) {
    final attributed = widget.axisGraduationTextFormatter?.call(
      this,
      direction,
      value,
    );
    if (attributed != null) {
      return attributed;
    }
    final text = widget.axisGraduationFormatter?.call(direction, value);
    return text == null ? null : TextSpan(text: text);
  }

  TextSpan _bottomAxisMaxMinTextFormatter(double x) {
    return widget.bottomAxisMaxMinTextFormatter?.call(this, x) ??
        TextSpan(
          text:
              widget.bottomAxisMaxMinFormatter?.call(x) ??
              LineChartMath.formatDate(x, 'yyyy-MM-dd HH:mm:ss'),
        );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _chartSize = Size(constraints.maxWidth, widget.height);
          return Listener(
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerUp,
            onPointerCancel: _handlePointerCancel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _handleTapUp,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: _handleScaleEnd,
              child: RepaintBoundary(
                child: CustomPaint(
                  size: _chartSize,
                  painter: LineChartPainter(
                    chartModel: _chartModel,
                    horizontalLineTextFormatter: _horizontalLineTextFormatter,
                    tappedItemTextFormatter: _tappedItemTextFormatter,
                    rightAxisDataMaxMinTextFormatter:
                        _rightAxisDataMaxMinTextFormatter,
                    axisGraduationTextFormatter: _axisGraduationTextFormatter,
                    bottomAxisMaxMinTextFormatter:
                        _bottomAxisMaxMinTextFormatter,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
