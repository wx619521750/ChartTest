import 'package:flutter/material.dart';

enum XSChartType {
  radon,
  temperature,
  humidity;

  String get title {
    switch (this) {
      case XSChartType.radon:
        return 'Radon';
      case XSChartType.temperature:
        return 'Temperature';
      case XSChartType.humidity:
        return 'Humidity';
    }
  }

  String get shortTitle {
    switch (this) {
      case XSChartType.radon:
        return 'Radon';
      case XSChartType.temperature:
        return 'Temp';
      case XSChartType.humidity:
        return 'Humidity';
    }
  }

  String get unit {
    switch (this) {
      case XSChartType.radon:
        return 'Bq/m3';
      case XSChartType.temperature:
        return 'C';
      case XSChartType.humidity:
        return '%';
    }
  }

  int get assetColumn {
    switch (this) {
      case XSChartType.radon:
        return 1;
      case XSChartType.temperature:
        return 2;
      case XSChartType.humidity:
        return 3;
    }
  }
}

enum DateMode { hour, day, week, month, year }

extension DateModeDuration on DateMode {
  Duration get duration {
    switch (this) {
      case DateMode.hour:
        return const Duration(hours: 1);
      case DateMode.day:
        return const Duration(days: 1);
      case DateMode.week:
        return const Duration(days: 7);
      case DateMode.month:
        return const Duration(days: 30);
      case DateMode.year:
        return const Duration(days: 360);
    }
  }

  String get label {
    switch (this) {
      case DateMode.hour:
        return 'Hour';
      case DateMode.day:
        return 'Day';
      case DateMode.week:
        return 'Week';
      case DateMode.month:
        return 'Month';
      case DateMode.year:
        return 'Year';
    }
  }
}

enum ChartPointDataType { data, gap }

enum DataLineKind { straight, bezier }

class DataLineStyle {
  const DataLineStyle({
    required this.kind,
    required this.width,
    required this.color,
  });

  const DataLineStyle.straight({required this.width, required this.color})
    : kind = DataLineKind.straight;

  const DataLineStyle.bezier({required this.width, required this.color})
    : kind = DataLineKind.bezier;

  final DataLineKind kind;
  final double width;
  final Color color;
}

enum LineStrokeKind { line, dashLine, none }

class ChartLineStyle {
  const ChartLineStyle._({
    required this.kind,
    required this.width,
    required this.color,
    required this.dashPattern,
  });

  const ChartLineStyle.line({required double width, required Color color})
    : this._(
        kind: LineStrokeKind.line,
        width: width,
        color: color,
        dashPattern: const [],
      );

  const ChartLineStyle.dashLine({
    required double width,
    required Color color,
    required List<double> lengths,
  }) : this._(
         kind: LineStrokeKind.dashLine,
         width: width,
         color: color,
         dashPattern: lengths,
       );

  const ChartLineStyle.none()
    : this._(
        kind: LineStrokeKind.none,
        width: 0,
        color: Colors.transparent,
        dashPattern: const [],
      );

  final LineStrokeKind kind;
  final double width;
  final Color color;
  final List<double> dashPattern;
}

enum AxisLabelPlacement { top, bottom, left, right, none }

class AxisLabelStyle {
  const AxisLabelStyle._({
    required this.placement,
    required this.color,
    required this.fontSize,
    required this.offset,
  });

  const AxisLabelStyle.top({
    required Color color,
    required double fontSize,
    double offset = 0,
  }) : this._(
         placement: AxisLabelPlacement.top,
         color: color,
         fontSize: fontSize,
         offset: offset,
       );

  const AxisLabelStyle.bottom({
    required Color color,
    required double fontSize,
    double offset = 0,
  }) : this._(
         placement: AxisLabelPlacement.bottom,
         color: color,
         fontSize: fontSize,
         offset: offset,
       );

  const AxisLabelStyle.left({
    required Color color,
    required double fontSize,
    double offset = 0,
  }) : this._(
         placement: AxisLabelPlacement.left,
         color: color,
         fontSize: fontSize,
         offset: offset,
       );

  const AxisLabelStyle.right({
    required Color color,
    required double fontSize,
    double offset = 0,
  }) : this._(
         placement: AxisLabelPlacement.right,
         color: color,
         fontSize: fontSize,
         offset: offset,
       );

  const AxisLabelStyle.none()
    : this._(
        placement: AxisLabelPlacement.none,
        color: Colors.transparent,
        fontSize: 0,
        offset: 0,
      );

  final AxisLabelPlacement placement;
  final Color color;
  final double fontSize;
  final double offset;

  bool get isVisible => placement != AxisLabelPlacement.none;

  TextStyle get textStyle => TextStyle(
    color: color,
    fontSize: fontSize,
    height: 1.1,
    letterSpacing: 0,
  );
}

enum AxisStepKind { dateAdapt, distance, separateCount, none }

class AxisStepType {
  const AxisStepType._({
    required this.kind,
    this.distance = 0,
    this.align,
    this.count = 0,
  });

  const AxisStepType.dateAdapt() : this._(kind: AxisStepKind.dateAdapt);

  const AxisStepType.distance({required double distance, double? align})
    : this._(kind: AxisStepKind.distance, distance: distance, align: align);

  const AxisStepType.separateCount({required int count})
    : this._(kind: AxisStepKind.separateCount, count: count);

  const AxisStepType.none() : this._(kind: AxisStepKind.none);

  final AxisStepKind kind;
  final double distance;
  final double? align;
  final int count;
}

enum YRangeMode {
  selfAdaptAll,
  selfAdaptVisible,
  selfAdaptVisibleWithType,
  selfAdaptVisibleWithMinMax,
  fixed,
}

class YRangeType {
  const YRangeType._({required this.mode, this.chartType, this.min, this.max});

  const YRangeType.selfAdaptAll() : this._(mode: YRangeMode.selfAdaptAll);

  const YRangeType.selfAdaptVisible()
    : this._(mode: YRangeMode.selfAdaptVisible);

  const YRangeType.selfAdaptVisibleWithType({required XSChartType chartType})
    : this._(mode: YRangeMode.selfAdaptVisibleWithType, chartType: chartType);

  const YRangeType.selfAdaptVisibleWithMinMax({
    required double min,
    required double max,
  }) : this._(mode: YRangeMode.selfAdaptVisibleWithMinMax, min: min, max: max);

  const YRangeType.fixed({required double min, required double max})
    : this._(mode: YRangeMode.fixed, min: min, max: max);

  final YRangeMode mode;
  final XSChartType? chartType;
  final double? min;
  final double? max;
}

enum XRangeMode { unlimited, limitedByData, distanceByNow }

class XRangeType {
  const XRangeType._({required this.mode, this.distanceByNow = 0});

  const XRangeType.unlimited() : this._(mode: XRangeMode.unlimited);

  const XRangeType.limitedByData() : this._(mode: XRangeMode.limitedByData);

  const XRangeType.distanceByNow(double distance)
    : this._(mode: XRangeMode.distanceByNow, distanceByNow: distance);

  final XRangeMode mode;
  final double distanceByNow;
}

enum GraduationKind { line, none }

class GraduationType {
  const GraduationType._({
    required this.kind,
    this.length = 0,
    this.width = 0,
    this.color = Colors.transparent,
  });

  const GraduationType.line({
    required double length,
    required double width,
    required Color color,
  }) : this._(
         kind: GraduationKind.line,
         length: length,
         width: width,
         color: color,
       );

  const GraduationType.none() : this._(kind: GraduationKind.none);

  final GraduationKind kind;
  final double length;
  final double width;
  final Color color;
}

class HorizontalEmptyAreaModel {
  HorizontalEmptyAreaModel({
    required this.left,
    required this.right,
    this.tapped = false,
  });

  final double left;
  final double right;
  bool tapped;
}

class VerticalColorRange {
  const VerticalColorRange({
    required this.top,
    required this.bottom,
    required this.color,
  });

  final double top;
  final double bottom;
  final Color color;
}

class HorizontalLine {
  const HorizontalLine({
    required this.y,
    required this.lineStyle,
    this.labelStyle = const AxisLabelStyle.none(),
  });

  final double y;
  final ChartLineStyle lineStyle;
  final AxisLabelStyle labelStyle;
}

class VerticalLine {
  const VerticalLine({required this.x, required this.lineStyle});

  final double x;
  final ChartLineStyle lineStyle;
}

class ChartPointModel {
  ChartPointModel({
    this.x = 0,
    this.y = 0,
    this.dataType = ChartPointDataType.data,
    this.gapLeft = 0,
    this.gapRight = 0,
    this.detailSize = const Size(80, 40),
  });

  double x;
  double y;
  ChartPointDataType dataType;
  double gapLeft;
  double gapRight;
  Size detailSize;

  ChartPointModel copy() => ChartPointModel(
    x: x,
    y: y,
    dataType: dataType,
    gapLeft: gapLeft,
    gapRight: gapRight,
    detailSize: detailSize,
  );
}

class ChartLineModel {
  ChartLineModel({
    DataLineStyle? dataLineStyle,
    List<ChartPointModel>? points,
    List<ChartPointModel>? pointsShouldDraw,
    List<HorizontalEmptyAreaModel>? emptyAreas,
  }) : dataLineStyle =
           dataLineStyle ??
           const DataLineStyle.bezier(width: 2, color: Colors.black),
       points = points ?? <ChartPointModel>[],
       pointsShouldDraw = pointsShouldDraw ?? <ChartPointModel>[],
       emptyAreas = emptyAreas ?? <HorizontalEmptyAreaModel>[];

  DataLineStyle dataLineStyle;
  List<ChartPointModel> points;
  List<ChartPointModel> pointsShouldDraw;
  List<HorizontalEmptyAreaModel> emptyAreas;

  ChartLineModel copy() => ChartLineModel(
    dataLineStyle: dataLineStyle,
    points: points.map((point) => point.copy()).toList(),
    pointsShouldDraw: pointsShouldDraw.map((point) => point.copy()).toList(),
    emptyAreas: emptyAreas
        .map(
          (area) => HorizontalEmptyAreaModel(
            left: area.left,
            right: area.right,
            tapped: area.tapped,
          ),
        )
        .toList(),
  );
}

class MaxMinModel {
  const MaxMinModel({required this.max, required this.min});

  final String max;
  final String min;
}

class ChartPalette {
  static const lineColorGreen = Color(0xff56c06f);
  static const lineColorYellow = Color(0xffffcf31);
  static const lineColorRed = Color(0xffe67077);
  static const lineColorBlue = Color(0xff68a7ed);
  static const axisLineColor = Color(0xffeeeeee);
  static const bottomLabelColor = Color(0xff666666);
  static const rightLabelColor = Color(0xff999999);
}

class ChartModel {
  ChartModel({
    ChartLineModel? lineModel,
    this.chartContentInset = const EdgeInsets.fromLTRB(40, 0, 40, 40),
    this.topAxisLineStyle = const ChartLineStyle.line(
      width: 1,
      color: Colors.black,
    ),
    this.bottomAxisLineStyle = const ChartLineStyle.line(
      width: 1,
      color: Colors.black,
    ),
    this.leftAxisLineStyle = const ChartLineStyle.line(
      width: 1,
      color: Colors.black,
    ),
    this.rightAxisLineStyle = const ChartLineStyle.line(
      width: 1,
      color: Colors.black,
    ),
    this.topAxisLabelStyle = const AxisLabelStyle.top(
      color: Colors.black,
      fontSize: 12,
    ),
    this.bottomAxisLabelStyle = const AxisLabelStyle.bottom(
      color: Colors.grey,
      fontSize: 12,
    ),
    this.leftAxisLabelStyle = const AxisLabelStyle.left(
      color: Colors.black,
      fontSize: 12,
    ),
    this.rightAxisLabelStyle = const AxisLabelStyle.right(
      color: Colors.black,
      fontSize: 12,
    ),
    this.topAxisStepType = const AxisStepType.none(),
    this.bottomAxisStepType = const AxisStepType.dateAdapt(),
    this.leftAxisStepType = const AxisStepType.distance(distance: 5, align: 5),
    this.rightAxisStepType = const AxisStepType.separateCount(count: 4),
    this.topAxisMaxMinStyle = const AxisLabelStyle.top(
      color: Colors.black,
      fontSize: 12,
    ),
    this.bottomAxisMaxMinStyle = const AxisLabelStyle.bottom(
      color: Colors.grey,
      fontSize: 12,
    ),
    this.leftAxisMaxMinStyle = const AxisLabelStyle.left(
      color: Colors.black,
      fontSize: 12,
    ),
    this.rightAxisMaxMinStyle = const AxisLabelStyle.right(
      color: Colors.black,
      fontSize: 12,
    ),
    this.rightAxisDataMaxMinStyle = const AxisLabelStyle.left(
      color: Colors.black,
      fontSize: 12,
    ),
    List<HorizontalLine>? horizontalLines,
    List<VerticalLine>? verticalLines,
    List<VerticalColorRange>? verticalColorRanges,
    this.dateMode = DateMode.day,
    this.minX = 0,
    this.maxX = 0,
    this.minY = 0,
    this.maxY = 0,
    this.tappedItem,
    this.yRangeType = const YRangeType.fixed(min: 19, max: 100),
    this.xRangeType = const XRangeType.unlimited(),
    this.horizontalAxisFullFrame = true,
    this.verticalAxisFullFrame = false,
    this.graduationType = const GraduationType.none(),
    this.enableDeceleration = true,
    this.chartType = XSChartType.radon,
  }) : lineModel = lineModel ?? ChartLineModel(),
       horizontalLines =
           horizontalLines ??
           const <HorizontalLine>[
             HorizontalLine(
               y: 60,
               lineStyle: ChartLineStyle.dashLine(
                 width: 1,
                 color: Colors.red,
                 lengths: [5, 5],
               ),
               labelStyle: AxisLabelStyle.left(color: Colors.red, fontSize: 11),
             ),
             HorizontalLine(
               y: 20,
               lineStyle: ChartLineStyle.dashLine(
                 width: 1,
                 color: Colors.green,
                 lengths: [5, 5],
               ),
               labelStyle: AxisLabelStyle.left(
                 color: Colors.green,
                 fontSize: 11,
               ),
             ),
           ],
       verticalLines = verticalLines ?? <VerticalLine>[],
       verticalColorRanges =
           verticalColorRanges ??
           const <VerticalColorRange>[
             VerticalColorRange(top: 100, bottom: 60, color: Colors.red),
             VerticalColorRange(top: 60, bottom: 20, color: Colors.yellow),
             VerticalColorRange(top: 20, bottom: 0, color: Colors.green),
           ];

  factory ChartModel.fromPoints({
    required List<ChartPointModel> points,
    required XSChartType type,
    double minThreshold = 30,
    double maxThreshold = 80,
    EdgeInsets? chartContentInset,
  }) {
    final model = ChartModel(chartType: type);
    model.lineModel.points = points.map((point) => point.copy()).toList();
    switch (type) {
      case XSChartType.radon:
        model.setupRadonStyle(
          minThreshold: minThreshold,
          maxThreshold: maxThreshold,
        );
      case XSChartType.temperature:
        model.setupTemperatureStyle();
      case XSChartType.humidity:
        model.setupHumidityStyle();
    }
    if (chartContentInset != null) {
      model.chartContentInset = chartContentInset;
    }
    return model;
  }

  ChartLineModel lineModel;
  EdgeInsets chartContentInset;
  ChartLineStyle topAxisLineStyle;
  ChartLineStyle bottomAxisLineStyle;
  ChartLineStyle leftAxisLineStyle;
  ChartLineStyle rightAxisLineStyle;
  AxisLabelStyle topAxisLabelStyle;
  AxisLabelStyle bottomAxisLabelStyle;
  AxisLabelStyle leftAxisLabelStyle;
  AxisLabelStyle rightAxisLabelStyle;
  AxisStepType topAxisStepType;
  AxisStepType bottomAxisStepType;
  AxisStepType leftAxisStepType;
  AxisStepType rightAxisStepType;
  AxisLabelStyle topAxisMaxMinStyle;
  AxisLabelStyle bottomAxisMaxMinStyle;
  AxisLabelStyle leftAxisMaxMinStyle;
  AxisLabelStyle rightAxisMaxMinStyle;
  AxisLabelStyle rightAxisDataMaxMinStyle;
  List<HorizontalLine> horizontalLines;
  List<VerticalLine> verticalLines;
  List<VerticalColorRange> verticalColorRanges;
  DateMode dateMode;
  double minX;
  double maxX;
  double minY;
  double maxY;
  ChartPointModel? tappedItem;
  YRangeType yRangeType;
  XRangeType xRangeType;
  bool horizontalAxisFullFrame;
  bool verticalAxisFullFrame;
  GraduationType graduationType;
  bool enableDeceleration;
  XSChartType chartType;

  ChartModel copy() => ChartModel(
    lineModel: lineModel.copy(),
    chartContentInset: chartContentInset,
    topAxisLineStyle: topAxisLineStyle,
    bottomAxisLineStyle: bottomAxisLineStyle,
    leftAxisLineStyle: leftAxisLineStyle,
    rightAxisLineStyle: rightAxisLineStyle,
    topAxisLabelStyle: topAxisLabelStyle,
    bottomAxisLabelStyle: bottomAxisLabelStyle,
    leftAxisLabelStyle: leftAxisLabelStyle,
    rightAxisLabelStyle: rightAxisLabelStyle,
    topAxisStepType: topAxisStepType,
    bottomAxisStepType: bottomAxisStepType,
    leftAxisStepType: leftAxisStepType,
    rightAxisStepType: rightAxisStepType,
    topAxisMaxMinStyle: topAxisMaxMinStyle,
    bottomAxisMaxMinStyle: bottomAxisMaxMinStyle,
    leftAxisMaxMinStyle: leftAxisMaxMinStyle,
    rightAxisMaxMinStyle: rightAxisMaxMinStyle,
    rightAxisDataMaxMinStyle: rightAxisDataMaxMinStyle,
    horizontalLines: List<HorizontalLine>.of(horizontalLines),
    verticalLines: List<VerticalLine>.of(verticalLines),
    verticalColorRanges: List<VerticalColorRange>.of(verticalColorRanges),
    dateMode: dateMode,
    minX: minX,
    maxX: maxX,
    minY: minY,
    maxY: maxY,
    tappedItem: tappedItem?.copy(),
    yRangeType: yRangeType,
    xRangeType: xRangeType,
    horizontalAxisFullFrame: horizontalAxisFullFrame,
    verticalAxisFullFrame: verticalAxisFullFrame,
    graduationType: graduationType,
    enableDeceleration: enableDeceleration,
    chartType: chartType,
  );

  void setupRadonStyle({
    required double minThreshold,
    required double maxThreshold,
  }) {
    chartContentInset = const EdgeInsets.fromLTRB(40, 0, 40, 40);
    yRangeType = YRangeType.selfAdaptVisibleWithMinMax(
      min: minThreshold,
      max: maxThreshold,
    );
    lineModel.dataLineStyle = const DataLineStyle.bezier(
      width: 3,
      color: Colors.black,
    );
    enableDeceleration = true;
    topAxisLineStyle = const ChartLineStyle.none();
    rightAxisLineStyle = const ChartLineStyle.dashLine(
      width: 1,
      color: ChartPalette.axisLineColor,
      lengths: [5, 5],
    );
    leftAxisLineStyle = const ChartLineStyle.none();
    bottomAxisLineStyle = const ChartLineStyle.dashLine(
      width: 1,
      color: ChartPalette.axisLineColor,
      lengths: [5, 5],
    );
    bottomAxisLabelStyle = const AxisLabelStyle.bottom(
      color: ChartPalette.bottomLabelColor,
      fontSize: 11,
      offset: 8,
    );
    rightAxisLabelStyle = const AxisLabelStyle.right(
      color: ChartPalette.rightLabelColor,
      fontSize: 11,
    );
    rightAxisStepType = const AxisStepType.distance(distance: 30, align: 30);
    rightAxisMaxMinStyle = const AxisLabelStyle.none();
    rightAxisDataMaxMinStyle = const AxisLabelStyle.left(
      color: ChartPalette.rightLabelColor,
      fontSize: 11,
    );
    bottomAxisMaxMinStyle = const AxisLabelStyle.bottom(
      color: ChartPalette.rightLabelColor,
      fontSize: 11,
    );
    horizontalLines = <HorizontalLine>[
      HorizontalLine(
        y: maxThreshold,
        lineStyle: const ChartLineStyle.dashLine(
          width: 1,
          color: ChartPalette.lineColorRed,
          lengths: [5, 5],
        ),
        labelStyle: const AxisLabelStyle.left(
          color: ChartPalette.lineColorRed,
          fontSize: 11,
        ),
      ),
      HorizontalLine(
        y: minThreshold,
        lineStyle: const ChartLineStyle.dashLine(
          width: 1,
          color: ChartPalette.lineColorGreen,
          lengths: [5, 5],
        ),
        labelStyle: const AxisLabelStyle.left(
          color: ChartPalette.lineColorGreen,
          fontSize: 11,
        ),
      ),
    ];
    verticalColorRanges = <VerticalColorRange>[
      VerticalColorRange(
        top: 1000,
        bottom: maxThreshold,
        color: ChartPalette.lineColorRed,
      ),
      VerticalColorRange(
        top: maxThreshold,
        bottom: minThreshold,
        color: ChartPalette.lineColorYellow,
      ),
      VerticalColorRange(
        top: minThreshold,
        bottom: 0,
        color: ChartPalette.lineColorGreen,
      ),
    ];
    horizontalAxisFullFrame = true;
    verticalAxisFullFrame = false;
    graduationType = const GraduationType.none();
    xRangeType = const XRangeType.distanceByNow(3600 * 24 * 365);
  }

  void setupTemperatureStyle() {
    chartContentInset = const EdgeInsets.fromLTRB(20, 0, 20, 40);
    yRangeType = const YRangeType.selfAdaptVisibleWithType(
      chartType: XSChartType.temperature,
    );
    lineModel.dataLineStyle = const DataLineStyle.bezier(
      width: 3,
      color: Colors.black,
    );
    enableDeceleration = true;
    topAxisLineStyle = const ChartLineStyle.none();
    rightAxisLineStyle = const ChartLineStyle.none();
    leftAxisLineStyle = const ChartLineStyle.none();
    bottomAxisLineStyle = const ChartLineStyle.dashLine(
      width: 1,
      color: ChartPalette.axisLineColor,
      lengths: [5, 5],
    );
    bottomAxisLabelStyle = const AxisLabelStyle.bottom(
      color: ChartPalette.bottomLabelColor,
      fontSize: 11,
      offset: 8,
    );
    rightAxisLabelStyle = const AxisLabelStyle.left(
      color: ChartPalette.rightLabelColor,
      fontSize: 11,
    );
    rightAxisMaxMinStyle = const AxisLabelStyle.none();
    rightAxisDataMaxMinStyle = const AxisLabelStyle.left(
      color: ChartPalette.rightLabelColor,
      fontSize: 11,
    );
    bottomAxisMaxMinStyle = const AxisLabelStyle.bottom(
      color: ChartPalette.rightLabelColor,
      fontSize: 11,
    );
    horizontalLines = <HorizontalLine>[];
    verticalColorRanges = const <VerticalColorRange>[
      VerticalColorRange(
        top: 100,
        bottom: -50,
        color: ChartPalette.lineColorBlue,
      ),
    ];
    horizontalAxisFullFrame = true;
    verticalAxisFullFrame = false;
    graduationType = const GraduationType.none();
    xRangeType = const XRangeType.distanceByNow(3600 * 24 * 365);
  }

  void setupHumidityStyle() {
    chartContentInset = const EdgeInsets.fromLTRB(20, 0, 20, 40);
    yRangeType = const YRangeType.selfAdaptVisibleWithType(
      chartType: XSChartType.humidity,
    );
    lineModel.dataLineStyle = const DataLineStyle.bezier(
      width: 3,
      color: Colors.black,
    );
    enableDeceleration = true;
    topAxisLineStyle = const ChartLineStyle.none();
    rightAxisLineStyle = const ChartLineStyle.none();
    leftAxisLineStyle = const ChartLineStyle.none();
    bottomAxisLineStyle = const ChartLineStyle.dashLine(
      width: 1,
      color: ChartPalette.axisLineColor,
      lengths: [5, 5],
    );
    bottomAxisLabelStyle = const AxisLabelStyle.bottom(
      color: ChartPalette.bottomLabelColor,
      fontSize: 11,
      offset: 8,
    );
    rightAxisLabelStyle = const AxisLabelStyle.left(
      color: ChartPalette.rightLabelColor,
      fontSize: 11,
    );
    rightAxisMaxMinStyle = const AxisLabelStyle.none();
    rightAxisDataMaxMinStyle = const AxisLabelStyle.left(
      color: ChartPalette.rightLabelColor,
      fontSize: 11,
    );
    bottomAxisMaxMinStyle = const AxisLabelStyle.bottom(
      color: ChartPalette.rightLabelColor,
      fontSize: 11,
    );
    horizontalLines = <HorizontalLine>[];
    verticalColorRanges = const <VerticalColorRange>[
      VerticalColorRange(
        top: 100,
        bottom: 0,
        color: ChartPalette.lineColorBlue,
      ),
    ];
    horizontalAxisFullFrame = true;
    verticalAxisFullFrame = false;
    graduationType = const GraduationType.none();
    xRangeType = const XRangeType.distanceByNow(3600 * 24 * 365);
  }
}
