import 'dart:convert';

import 'package:flutter/services.dart';

import 'line_chart_models.dart';

class DemoChartData {
  static Future<Map<XSChartType, List<ChartPointModel>>> load() async {
    final raw = await rootBundle.loadString('assets/aaa.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final result = <XSChartType, List<ChartPointModel>>{
      for (final type in XSChartType.values) type: <ChartPointModel>[],
    };

    final dayKeys = json.keys.toList()..sort();
    for (final dayKey in dayKeys) {
      final rows = (json[dayKey] as List<dynamic>).cast<String>();
      for (final row in rows) {
        final parts = row.split(',');
        if (parts.length < 4 || parts.first.length != 6 || dayKey.length != 8) {
          continue;
        }
        final timestamp = _parseTimestamp(dayKey, parts.first);
        for (final type in XSChartType.values) {
          final value = double.tryParse(parts[type.assetColumn]);
          if (value == null) {
            continue;
          }
          result[type]!.add(ChartPointModel(x: timestamp, y: value));
        }
      }
    }

    for (final points in result.values) {
      points.sort((a, b) => a.x.compareTo(b.x));
    }
    return result;
  }

  static double _parseTimestamp(String dayKey, String timeKey) {
    final year = int.parse(dayKey.substring(0, 4));
    final month = int.parse(dayKey.substring(4, 6));
    final day = int.parse(dayKey.substring(6, 8));
    final hour = int.parse(timeKey.substring(0, 2));
    final minute = int.parse(timeKey.substring(2, 4));
    final second = int.parse(timeKey.substring(4, 6));
    return DateTime(
          year,
          month,
          day,
          hour,
          minute,
          second,
        ).millisecondsSinceEpoch /
        1000;
  }
}
