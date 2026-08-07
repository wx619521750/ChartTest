import UIKit

/// 负责原始数据处理、选中状态和点击交互；具体绘制由 BinaryTimelineDrawer 完成。
final class BinaryTimelineChartView: UIView {
    var chartModel = BinaryTimelineChartModel() {
        didSet { reloadData() }
    }

    private let drawer = BinaryTimelineDrawer()
    private let calendar = Calendar.current
    private var dayRange: Range<TimeInterval>?
    private var stateBlocks: [BinaryTimelineStateBlock] = []
    private var activeRanges: [Range<TimeInterval>] = []
    private var selectedRangeIndex: Int?

    /// 代码创建 View 时调用，完成父类初始化后统一执行视图基础配置。
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    /// Storyboard 或 XIB 创建 View 时调用，保证两种初始化入口的配置一致。
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    /// 系统触发重绘时调用；View 负责准备数据，真正的路径绘制交给 Drawer。
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let dayRange else { return }
        // View 只向 Drawer 传递当前选中区间，不参与任何路径绘制。
        let selectedRange = selectedRangeIndex.flatMap { index in
            activeRanges.indices.contains(index) ? activeRanges[index] : nil
        }
        drawer.draw(
            context: context,
            bounds: bounds,
            model: chartModel,
            dayRange: dayRange,
            blocks: stateBlocks,
            selectedRange: selectedRange
        )
    }

    /// 模型内容发生变化后重新排序、归一化并生成可绘制状态块。
    func reloadData() {
        // 所有区间计算都依赖时间顺序，先统一排序再处理。
        let sortedPoints = chartModel.points.sorted { $0.x < $1.x }
        chartModel.points = sortedPoints

        guard let firstPoint = sortedPoints.first,
              let range = makeDayRange(containing: firstPoint.x) else {
            dayRange = nil
            stateBlocks = []
            activeRanges = []
            selectedRangeIndex = nil
            setNeedsDisplay()
            return
        }

        dayRange = range
        // 多个连续相同 y 值只生成一个状态块，避免内部出现多余接缝和圆角。
        stateBlocks = makeStateBlocks(points: sortedPoints, dayRange: range)
        activeRanges = stateBlocks.filter { $0.value == 1 }.map(\.range)
        if let selectedRangeIndex, activeRanges.indices.contains(selectedRangeIndex) {
            self.selectedRangeIndex = selectedRangeIndex
        } else {
            selectedRangeIndex = activeRanges.indices.first
        }
        backgroundColor = chartModel.backgroundColor
        setNeedsDisplay()
    }

    /// 初始化 View 的基础显示属性和点击手势。
    private func setupView() {
        backgroundColor = chartModel.backgroundColor
        isOpaque = true
        contentMode = .redraw
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap(_:))))
    }

    /// 处理点击选中逻辑；只允许选中连续的 y=1 区间。
    @objc private func didTap(_ gesture: UITapGestureRecognizer) {
        guard chartModel.showsSelection, let dayRange else { return }
        // 点击位置先转换为当天时间戳，再命中连续的 y=1 区间。
        let timestamp = drawer.timestamp(
            at: gesture.location(in: self).x,
            bounds: bounds,
            model: chartModel,
            dayRange: dayRange
        )
        guard let index = activeRanges.firstIndex(where: { $0.contains(timestamp) }) else { return }
        selectedRangeIndex = index
        setNeedsDisplay()
    }

    /// 使用 Calendar 计算自然日边界，兼容包含夏令时变化的日期。
    private func makeDayRange(containing timestamp: TimeInterval) -> Range<TimeInterval>? {
        let date = Date(timeIntervalSince1970: timestamp)
        let startDate = calendar.startOfDay(for: date)
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else { return nil }
        return startDate.timeIntervalSince1970..<endDate.timeIntervalSince1970
    }

    /// 将当天可见点合并为连续状态块，减少绘制时的重复路径和多余圆角。
    private func makeStateBlocks(
        points: [BinaryTimelinePointModel],
        dayRange: Range<TimeInterval>
    ) -> [BinaryTimelineStateBlock] {
        var visiblePoints = points.filter { dayRange.contains($0.x) }
        guard !visiblePoints.isEmpty else { return [] }

        // 当首个数据点晚于 00:00 时，默认当天开始处于 y=0 状态。
        if visiblePoints[0].x > dayRange.lowerBound {
            visiblePoints.insert(
                BinaryTimelinePointModel(x: dayRange.lowerBound, y: 0),
                at: 0
            )
        }

        var blocks: [BinaryTimelineStateBlock] = []
        var start = visiblePoints[0].x
        var value = visiblePoints[0].y
        // 只有状态改变时才结束当前块，重复的相同状态点不会拆分区间。
        for point in visiblePoints.dropFirst() where point.y != value {
            if point.x > start {
                blocks.append(BinaryTimelineStateBlock(start: start, end: point.x, value: value))
            }
            start = point.x
            value = point.y
        }
        // 最后一个状态持续到当天结束 24:00。
        if dayRange.upperBound > start {
            blocks.append(BinaryTimelineStateBlock(start: start, end: dayRange.upperBound, value: value))
        }
        return blocks
    }
}
