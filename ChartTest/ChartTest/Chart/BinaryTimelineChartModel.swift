import UIKit

/// 二值时间轴的原始数据点。x 为任意时间戳，y 只保留 0 或 1。
final class BinaryTimelinePointModel {
    /// 状态发生或被采样时的 Unix 时间戳，单位为秒。
    var x: TimeInterval
    /// 内部保存的归一化状态，始终为 0 或 1。
    private var storedY: Int

    /// 二值状态；赋入 0 时保存为 0，其他值统一保存为 1。
    var y: Int {
        get { storedY }
        // 对外赋值时统一归一化，避免 Drawer 处理非法状态值。
        set { storedY = newValue == 0 ? 0 : 1 }
    }

    /// 创建一个时间状态点，并立即将状态归一化为 0 或 1。
    init(x: TimeInterval, y: Int) {
        self.x = x
        storedY = y == 0 ? 0 : 1
    }
}

/// 二值时间轴的通用数据和外观配置。
final class BinaryTimelineChartModel {
    /// 时间轴原始数据点；View 重载数据时会按时间戳升序排列。
    var points: [BinaryTimelinePointModel]

    // MARK: - Colors

    /// 整个图表的背景色。
    var backgroundColor = UIColor.white
    /// y=0 状态块及渐变连接线底端的颜色。
    var inactiveColor = UIColor(red: 0.89, green: 0.95, blue: 0.98, alpha: 1)
    /// y=1 状态块及渐变连接线顶端的颜色。
    var activeColor = UIColor(red: 0.98, green: 0.22, blue: 0.24, alpha: 1)
    /// 底部时间刻度文本颜色。
    var axisTextColor = UIColor(white: 0.48, alpha: 1)
    /// 选中提示框背景色。
    var tooltipBackgroundColor = UIColor(white: 0.04, alpha: 1)
    /// 选中提示框内的文本颜色。
    var tooltipTextColor = UIColor.white
    /// 提示框与选中状态块之间引导线的颜色。
    var selectionLineColor = UIColor(white: 0.72, alpha: 1)

    // MARK: - Layout

    /// 绘图区边距；顶部需要为提示框预留空间，底部需要为时间刻度预留空间。
    var contentInsets = UIEdgeInsets(top: 50, left: 0, bottom: 50, right: 0)
    /// 红、灰状态块的高度。
    var blockHeight: CGFloat = 18
    /// 红色块中心与灰色块中心之间的垂直距离。
    var stateVerticalDistance: CGFloat = 36
    /// 红灰状态切换时竖向渐变连接线的宽度。
    var connectorWidth: CGFloat = 1
    /// 色块最大圆角；当色块宽度不足两倍圆角时，实际圆角使用宽度的一半。
    var maximumCornerRadius: CGFloat = 4
    /// 时间刻度文本底边相对 View 底部的距离。
    var axisLabelBottom: CGFloat = 34
    /// 底部时间刻度字体。
    var axisFont = UIFont.systemFont(ofSize: 14)
    /// 是否显示底部时间刻度文本。
    var showsAxisLabels = true
    /// 是否将首尾时间文本自动缩进 View 边界内；false 时按真实时间位置居中。
    var automaticallyInsetsAxisLabels = true

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
    /// 设置模型或重新加载数据时，是否播放从左到右的加载动画。
    var enableLoadAnimation = true
    /// 加载动画时长，默认 400ms。
    var loadAnimationDuration: TimeInterval = 0.4

    // MARK: - Selection

    /// 是否允许显示和拖动选中提示框。
    var showsSelection = true
    /// 提示框顶部相对 View 顶部的位置，单位为 pt。
    var tooltipTop: CGFloat = 8
    /// 提示框内文本左右留白，单位为 pt。
    var tooltipHorizontalPadding: CGFloat = 12
    /// 提示框内文本上下留白，单位为 pt。
    var tooltipVerticalPadding: CGFloat = 9
    /// 提示框圆角半径，单位为 pt。
    var tooltipCornerRadius: CGFloat = 9
    /// 提示框两行文本使用的字体。
    var tooltipFont = UIFont.systemFont(ofSize: 15)
    /// 选中引导线宽度，单位为 pt。
    var selectionLineWidth: CGFloat = 1
    /// 选中引导线的虚线线段与间隔长度，单位为 pt。
    var selectionLineDash: [CGFloat] = [2, 3]

    /// 使用指定数据点创建图表配置；其余外观和交互参数使用默认值。
    init(points: [BinaryTimelinePointModel] = []) {
        self.points = points
    }
}

/// View 将连续相同状态的数据点合并后生成的绘制区间。
struct BinaryTimelineStateBlock {
    /// 状态块起始时间戳，单位为秒。
    let start: TimeInterval
    /// 状态块结束时间戳，单位为秒，不包含该边界。
    let end: TimeInterval
    /// 当前区间的二值状态，0 为非活动，1 为活动。
    let value: Int

    /// 将起止时间包装为左闭右开的时间范围，供绘制和选中逻辑复用。
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
