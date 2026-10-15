# flutter_line_chart

Flutter recreation of the custom iOS `LineChartView` from the sibling
`ChartTest` project.

## What is included

- `CustomPainter` based line chart rendering.
- Radon, temperature, and humidity chart style presets.
- Time-window switching for day, week, month, and year.
- Horizontal pan, pinch zoom, tap selection, tooltip display, and deceleration.
- Visible-range Y-axis adaptation, threshold lines, colored line ranges, max/min
  labels, date ticks, and gap rendering.
- Demo data loaded from `assets/aaa.json`.

## Run

```sh
flutter run
```

## Verify

```sh
flutter analyze
flutter test
```
