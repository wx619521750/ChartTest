import 'package:flutter/material.dart';

import 'chart/demo_chart_data.dart';
import 'chart/line_chart_math.dart';
import 'chart/line_chart_models.dart';
import 'chart/line_chart_view.dart';

void main() {
  runApp(const LineChartDemoApp());
}

class LineChartDemoApp extends StatelessWidget {
  const LineChartDemoApp({super.key, this.initialPointsByType});

  final Map<XSChartType, List<ChartPointModel>>? initialPointsByType;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Line Chart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2f7d7a),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff5f7f6),
        useMaterial3: true,
      ),
      home: ChartDemoPage(initialPointsByType: initialPointsByType),
    );
  }
}

class ChartDemoPage extends StatefulWidget {
  const ChartDemoPage({super.key, this.initialPointsByType});

  final Map<XSChartType, List<ChartPointModel>>? initialPointsByType;

  @override
  State<ChartDemoPage> createState() => _ChartDemoPageState();
}

class _ChartDemoPageState extends State<ChartDemoPage> {
  final Map<XSChartType, GlobalKey<FlutterLineChartViewState>> _chartKeys = {
    for (final type in XSChartType.values)
      type: GlobalKey<FlutterLineChartViewState>(),
  };
  Map<XSChartType, List<ChartPointModel>> _pointsByType = const {};
  Map<XSChartType, ChartModel> _models = const {};
  final Map<XSChartType, (double, double)> _yRanges = {};
  DateMode _selectedMode = DateMode.day;
  double? _minX;
  double? _maxX;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    final initialPoints = widget.initialPointsByType;
    if (initialPoints == null) {
      _loadData();
    } else {
      _pointsByType = initialPoints;
      _models = {
        for (final type in XSChartType.values) type: _createModel(type),
      };
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromRadon());
    }
  }

  Future<void> _loadData() async {
    try {
      final points = await DemoChartData.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _pointsByType = points;
        _models = {
          for (final type in XSChartType.values) type: _createModel(type),
        };
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromRadon());
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loadError = error);
    }
  }

  ChartModel _createModel(XSChartType type) {
    final model = ChartModel.fromPoints(
      points: _pointsByType[type] ?? <ChartPointModel>[],
      type: type,
    );
    // The bundled sample data is historical, so the demo uses data bounds.
    // The original distance-by-now mode is still available on ChartModel.
    model.xRangeType = const XRangeType.limitedByData();
    model.dateMode = _selectedMode;
    return model;
  }

  void _syncFromRadon() {
    if (!mounted) {
      return;
    }
    final source = _chartKeys[XSChartType.radon]?.currentState;
    if (source == null) {
      return;
    }
    _syncVisibleRange(
      min: source.chartModel.minX,
      max: source.chartModel.maxX,
      source: source,
    );
  }

  void _selectDateMode(DateMode mode) {
    setState(() => _selectedMode = mode);
    final source = _chartKeys[XSChartType.radon]?.currentState;
    source?.changeDateMode(mode);
    if (source != null) {
      _syncVisibleRange(
        min: source.chartModel.minX,
        max: source.chartModel.maxX,
        source: source,
      );
    }
  }

  void _handleXRangeChanged(
    FlutterLineChartViewState chartView,
    double min,
    double max,
  ) {
    if (_minX == min && _maxX == max) {
      return;
    }
    setState(() {
      _minX = min;
      _maxX = max;
    });
  }

  void _handleUserXRangeChanged(
    FlutterLineChartViewState chartView,
    double min,
    double max,
  ) {
    _syncVisibleRange(min: min, max: max, source: chartView);
  }

  void _syncVisibleRange({
    required double min,
    required double max,
    FlutterLineChartViewState? source,
  }) {
    if (min >= max) {
      return;
    }
    for (final key in _chartKeys.values) {
      final chartView = key.currentState;
      if (chartView != null && chartView != source) {
        chartView.changeXRange(min: min, max: max);
      }
    }
    _updateXRange(min, max);
  }

  void _updateXRange(double min, double max) {
    if (!mounted || (_minX == min && _maxX == max)) {
      return;
    }
    setState(() {
      _minX = min;
      _maxX = max;
    });
  }

  void _handleYRangeChanged(
    FlutterLineChartViewState chartView,
    double min,
    double max,
  ) {
    final type = chartView.chartModel.chartType;
    if (_yRanges[type] == (min, max)) {
      return;
    }
    setState(() => _yRanges[type] = (min, max));
  }

  void _handleDateModeChanged(
    FlutterLineChartViewState chartView,
    DateMode mode,
  ) {
    if (_selectedMode == mode) {
      return;
    }
    setState(() => _selectedMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LineChartView Flutter'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _loadError != null
            ? Center(child: Text('Load failed: $_loadError'))
            : _models.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  for (final type in XSChartType.values) ...[
                    _buildChartPanel(type, _models[type]!),
                    const SizedBox(height: 12),
                  ],
                  _buildDateModeControl(),
                  const SizedBox(height: 12),
                  _buildDateRangeControls(),
                  const SizedBox(height: 12),
                  _buildYRangeStrip(),
                ],
              ),
      ),
    );
  }

  Widget _buildChartPanel(XSChartType type, ChartModel model) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffe0e6e3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
            child: Row(
              children: [
                Text(
                  type.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(),
                Text(
                  type.unit,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xff66736f),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          FlutterLineChartView(
            key: _chartKeys[type],
            model: model,
            height: 240,
            onDateModeChangedWithChart: _handleDateModeChanged,
            onXRangeChangedWithChart: _handleXRangeChanged,
            onXRangeChangedByUserInteraction: _handleUserXRangeChanged,
            onYRangeChangedWithChart: _handleYRangeChanged,
            // horizontalLineTextFormatter: _formatHorizontalLine,
            // tappedItemTextFormatter: _formatTappedItem,
            // rightAxisDataMaxMinTextFormatter: _formatRightAxisDataRange,
            // axisGraduationTextFormatter: _formatAxisGraduation,
            // bottomAxisMaxMinTextFormatter: _formatBottomAxisRange,
          ),
        ],
      ),
    );
  }

  Widget _buildDateModeControl() {
    return SegmentedButton<DateMode>(
      segments: const [
        ButtonSegment(value: DateMode.day, label: Text('Day')),
        ButtonSegment(value: DateMode.week, label: Text('Week')),
        ButtonSegment(value: DateMode.month, label: Text('Month')),
        ButtonSegment(value: DateMode.year, label: Text('Year')),
      ],
      selected: {_selectedMode},
      onSelectionChanged: (selection) => _selectDateMode(selection.first),
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -1, vertical: -1),
      ),
    );
  }

  Widget _buildDateRangeControls() {
    return Row(
      children: [
        Expanded(child: _buildDateButton(isMinimum: true)),
        const SizedBox(width: 8),
        Expanded(child: _buildDateButton(isMinimum: false)),
      ],
    );
  }

  Widget _buildDateButton({required bool isMinimum}) {
    final value = isMinimum ? _minX : _maxX;
    final label = value == null
        ? '--'
        : LineChartMath.formatDate(value, 'yyyy/MM/dd HH:mm');
    return OutlinedButton.icon(
      onPressed: value == null
          ? null
          : () => _pickDateTime(isMinimum: isMinimum),
      icon: const Icon(Icons.calendar_month_outlined, size: 18),
      label: Text(
        '${isMinimum ? 'From' : 'To'}\n$label',
        textAlign: TextAlign.left,
      ),
      style: const ButtonStyle(
        alignment: Alignment.centerLeft,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Future<void> _pickDateTime({required bool isMinimum}) async {
    final seconds = isMinimum ? _minX : _maxX;
    if (seconds == null) {
      return;
    }
    final initial = DateTime.fromMillisecondsSinceEpoch(
      (seconds * 1000).round(),
    );
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) {
      return;
    }
    final selected =
        DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ).millisecondsSinceEpoch /
        1000;
    final min = isMinimum ? selected : _minX!;
    final max = isMinimum ? _maxX! : selected;
    if (min >= max) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The start time must be before the end time.'),
        ),
      );
      return;
    }
    _syncVisibleRange(min: min, max: max);
  }

  Widget _buildYRangeStrip() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in XSChartType.values)
          _RangePill(
            label: type.shortTitle,
            value: _formatYRange(_yRanges[type]),
          ),
      ],
    );
  }

  String _formatYRange((double, double)? range) {
    return range == null
        ? '--'
        : '${range.$1.toStringAsFixed(1)} - ${range.$2.toStringAsFixed(1)}';
  }

  TextSpan _formatHorizontalLine(
    FlutterLineChartViewState chartView,
    double y,
  ) {
    return TextSpan(text: '$y', style: _demoTextStyle);
  }

  XYTextModel _formatTappedItem(
    FlutterLineChartViewState chartView,
    double x,
    double y,
  ) {
    return XYTextModel(
      xText: TextSpan(
        text: LineChartMath.formatDate(x, 'yyyy/MM/dd HH:mm'),
        style: _demoTextStyle,
      ),
      yText: TextSpan(
        text: '$y ${chartView.chartModel.chartType.unit}',
        style: _demoTextStyle.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  MaxMinTextModel _formatRightAxisDataRange(
    FlutterLineChartViewState chartView,
    double min,
    double max,
  ) {
    return MaxMinTextModel(
      max: TextSpan(text: 'Max:${max.floor()}', style: _demoTextStyle),
      min: TextSpan(text: 'Min:${min.floor()}', style: _demoTextStyle),
    );
  }

  TextSpan? _formatAxisGraduation(
    FlutterLineChartViewState chartView,
    AxisLabelPlacement direction,
    double value,
  ) {
    switch (direction) {
      case AxisLabelPlacement.bottom:
        return TextSpan(
          text: LineChartMath.formatDate(value, 'yyyy'),
          style: _demoTextStyle,
        );
      case AxisLabelPlacement.right:
        return TextSpan(text: value.toStringAsFixed(1), style: _demoTextStyle);
      case AxisLabelPlacement.top:
      case AxisLabelPlacement.left:
      case AxisLabelPlacement.none:
        return null;
    }
  }

  TextSpan _formatBottomAxisRange(
    FlutterLineChartViewState chartView,
    double x,
  ) {
    return TextSpan(
      text: LineChartMath.formatDate(x, 'yyyy/MM/dd HH:mm'),
      style: _demoTextStyle,
    );
  }

  static const _demoTextStyle = TextStyle(
    color: Colors.red,
    fontSize: 18,
    height: 1.1,
    letterSpacing: 0,
  );
}

class _RangePill extends StatelessWidget {
  const _RangePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffdde5e1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xff54736d),
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xff2f3432),
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
