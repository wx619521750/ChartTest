import UIKit

/// 二值时间轴的原始数据点。x 为任意时间戳，y 只保留 0 或 1。
final class BinaryTimelinePointModel {
    var x: TimeInterval
    private var storedY: Int

    var y: Int {
        get { storedY }
        // 对外赋值时统一归一化，避免 Drawer 处理非法状态值。
        set { storedY = newValue == 0 ? 0 : 1 }
    }

    init(x: TimeInterval, y: Int) {
        self.x = x
        storedY = y == 0 ? 0 : 1
    }
}

/// 二值时间轴的通用数据和外观配置。
final class BinaryTimelineChartModel {
    var points: [BinaryTimelinePointModel]

    // MARK: - Colors

    var backgroundColor = UIColor.white
    var inactiveColor = UIColor(red: 0.89, green: 0.95, blue: 0.98, alpha: 1)
    var activeColor = UIColor(red: 0.98, green: 0.22, blue: 0.24, alpha: 1)
    var axisTextColor = UIColor(white: 0.48, alpha: 1)
    var tooltipBackgroundColor = UIColor(white: 0.04, alpha: 1)
    var tooltipTextColor = UIColor.white
    var selectionLineColor = UIColor(white: 0.72, alpha: 1)

    // MARK: - Layout

    /// 绘图区边距；顶部需要为提示框预留空间，底部需要为时间刻度预留空间。
    var contentInsets = UIEdgeInsets(top: 50, left: 0, bottom: 50, right: 0)
    /// 红、灰状态块的高度。
    var blockHeight: CGFloat = 18
    /// 红色块中心与灰色块中心之间的垂直距离。
    var stateVerticalDistance: CGFloat = 36
    /// 红灰状态切换时竖向渐变连接线的宽度。
    var connectorWidth: CGFloat = 3
    /// 色块最大圆角；当色块宽度不足两倍圆角时，实际圆角使用宽度的一半。
    var maximumCornerRadius: CGFloat = 4
    /// 时间刻度文本底边相对 View 底部的距离。
    var axisLabelBottom: CGFloat = 34
    /// 底部时间刻度字体。
    var axisFont = UIFont.systemFont(ofSize: 14)

    // MARK: - Range

    /// 当前可视窗口的最小 X 时间戳。
    var minX: TimeInterval = 0
    /// 当前可视窗口的最大 X 时间戳。
    var maxX: TimeInterval = 0
    /// X 轴滑动和缩放边界。
    var XRangeType: BinaryTimelineXRangeType = .limitedByData
    /// 允许缩放到的最小可视时间跨度，默认 30 分钟。
    var minimumVisibleDuration: TimeInterval = 1800
    /// 允许缩放到的最大可视时间跨度；nil 表示不额外限制。
    var maximumVisibleDuration: TimeInterval?

    // MARK: - Interaction

    /// 是否允许左右平移。
    var enablePan = true
    /// 是否允许双指缩放。
    var enablePinch = true
    /// 是否开启左右滑动惯性。
    var enableDeceleration = true

    // MARK: - Selection

    var showsSelection = true
    var tooltipTop: CGFloat = 8
    var tooltipHorizontalPadding: CGFloat = 12
    var tooltipVerticalPadding: CGFloat = 9
    var tooltipCornerRadius: CGFloat = 9
    var tooltipFont = UIFont.systemFont(ofSize: 15)
    var selectionLineWidth: CGFloat = 1
    var selectionLineDash: [CGFloat] = [2, 3]

    init(points: [BinaryTimelinePointModel] = []) {
        self.points = points
    }
}

/// View 将连续相同状态的数据点合并后生成的绘制区间。
struct BinaryTimelineStateBlock {
    let start: TimeInterval
    let end: TimeInterval
    let value: Int

    var range: Range<TimeInterval> { start..<end }
}

/// 二值时间轴的 X 轴交互范围限制。
enum BinaryTimelineXRangeType {
    /// 不限制边界，图表可以任意滑动和缩放。
    case unlimited
    /// 限制在数据首尾时间范围内。
    case limitedByData
    /// 限制在指定的最小和最大时间范围内。
    case limited(minX: TimeInterval, maxX: TimeInterval)
    /// 限制在当前时间往前固定时长的范围内。
    case distanceByNow(TimeInterval)
}
