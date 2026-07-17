import 'package:flutter/material.dart';

import 'chart/demo_chart_data.dart';
import 'chart/line_chart_math.dart';
import 'chart/line_chart_models.dart';
import 'chart/line_chart_view.dart';

void main() {
  runApp(const LineChartDemoApp());
}

class LineChartDemoApp extends StatelessWidget {
  const LineChartDemoApp({super.key});

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
      home: const ChartDemoPage(),
    );
  }
}

class ChartDemoPage extends StatefulWidget {
  const ChartDemoPage({super.key});

  @override
  State<ChartDemoPage> createState() => _ChartDemoPageState();
}

class _ChartDemoPageState extends State<ChartDemoPage> {
  final _chartKey = GlobalKey<FlutterLineChartViewState>();
  Map<XSChartType, List<ChartPointModel>> _pointsByType = const {};
  ChartModel? _model;
  XSChartType _selectedType = XSChartType.radon;
  DateMode _selectedMode = DateMode.day;
  double? _minX;
  double? _maxX;
  double? _minY;
  double? _maxY;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final points = await DemoChartData.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _pointsByType = points;
        _model = _createModel(_selectedType);
      });
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

  void _selectType(XSChartType type) {
    if (type == _selectedType) {
      return;
    }
    setState(() {
      _selectedType = type;
      _selectedMode = DateMode.day;
      _model = _createModel(type);
      _minX = null;
      _maxX = null;
      _minY = null;
      _maxY = null;
    });
  }

  void _selectDateMode(DateMode mode) {
    setState(() => _selectedMode = mode);
    _chartKey.currentState?.changeDateMode(mode);
  }

  void _handleXRangeChanged(double min, double max) {
    if (_minX == min && _maxX == max) {
      return;
    }
    setState(() {
      _minX = min;
      _maxX = max;
    });
  }

  void _handleYRangeChanged(double min, double max) {
    if (_minY == min && _maxY == max) {
      return;
    }
    setState(() {
      _minY = min;
      _maxY = max;
    });
  }

  void _handleDateModeChanged(DateMode mode) {
    if (_selectedMode == mode) {
      return;
    }
    setState(() => _selectedMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LineChartView Flutter'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _loadError != null
            ? Center(child: Text('Load failed: $_loadError'))
            : model == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _buildTypeControl(),
                  const SizedBox(height: 12),
                  _buildChartPanel(model),
                  const SizedBox(height: 12),
                  _buildDateModeControl(),
                  const SizedBox(height: 12),
                  _buildRangeStrip(),
                ],
              ),
      ),
    );
  }

  Widget _buildTypeControl() {
    return SegmentedButton<XSChartType>(
      segments: const [
        ButtonSegment(
          value: XSChartType.radon,
          label: Text('Radon'),
          icon: Icon(Icons.blur_on),
        ),
        ButtonSegment(
          value: XSChartType.temperature,
          label: Text('Temp'),
          icon: Icon(Icons.device_thermostat),
        ),
        ButtonSegment(
          value: XSChartType.humidity,
          label: Text('Humidity'),
          icon: Icon(Icons.water_drop_outlined),
        ),
      ],
      selected: {_selectedType},
      onSelectionChanged: (selection) => _selectType(selection.first),
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -1, vertical: -1),
      ),
    );
  }

  Widget _buildChartPanel(ChartModel model) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffe0e6e3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: FlutterLineChartView(
          key: _chartKey,
          model: model,
          height: 260,
          onDateModeChanged: _handleDateModeChanged,
          onXRangeChanged: _handleXRangeChanged,
          onYRangeChanged: _handleYRangeChanged,
          horizontalLineFormatter: (y) => y.toStringAsFixed(0),
          tappedItemFormatter: _formatTappedItem,
          rightAxisDataMaxMinFormatter: (min, max) =>
              MaxMinModel(max: 'Max:${max.floor()}', min: 'Min:${min.floor()}'),
          axisGraduationFormatter: (_, value) => value.toStringAsFixed(1),
          bottomAxisMaxMinFormatter: (x) =>
              LineChartMath.formatDate(x, 'yyyy/MM/dd HH:mm'),
        ),
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

  Widget _buildRangeStrip() {
    final xRange = _minX == null || _maxX == null
        ? '--'
        : '${LineChartMath.formatDate(_minX!, 'yyyy/MM/dd HH:mm')}  -  '
              '${LineChartMath.formatDate(_maxX!, 'yyyy/MM/dd HH:mm')}';
    final yRange = _minY == null || _maxY == null
        ? '--'
        : '${_minY!.toStringAsFixed(1)}  -  ${_maxY!.toStringAsFixed(1)}';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _RangePill(label: 'X', value: xRange),
        _RangePill(label: 'Y', value: yRange),
      ],
    );
  }

  List<String> _formatTappedItem(ChartPointModel item) {
    return <String>[
      '${item.y.toStringAsFixed(1)} ${_selectedType.unit}',
      LineChartMath.formatDate(item.x, 'yyyy/MM/dd HH:mm'),
    ];
  }
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
