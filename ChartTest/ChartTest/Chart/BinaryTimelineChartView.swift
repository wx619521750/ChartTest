import UIKit

/// 负责原始数据处理、选中状态、平移缩放和点击交互；具体绘制由 BinaryTimelineDrawer 完成。
final class BinaryTimelineChartView: UIView, UIGestureRecognizerDelegate {
    /// 图表数据与配置；替换整个模型时会重新整理数据并播放配置的加载动画。
    var chartModel = BinaryTimelineChartModel() {
        didSet { reloadData() }
    }

    /// 负责坐标换算和 Core Graphics 绘制的对象，View 本身只管理数据与交互。
    private let drawer = BinaryTimelineDrawer()
    /// 原始数据或 XRangeType 配置允许覆盖的完整时间范围。
    private var dataRange: Range<TimeInterval>?
    /// 当前屏幕实际展示的时间范围，平移和缩放都会更新它。
    private var visibleRange: Range<TimeInterval>?
    /// 当前可视范围内合并后的连续 0/1 状态块。
    private var stateBlocks: [BinaryTimelineStateBlock] = []
    /// 从状态块中提取的 y=1 区间，作为 tooltip 的可选目标。
    private var activeRanges: [Range<TimeInterval>] = []
    /// 当前 tooltip 对应的实际时间范围；保存范围而非数组下标，避免平移后错误切换选中项。
    private var selectedRange: Range<TimeInterval>?
    /// 当前平移手势是否从 tooltip 内开始，并用于拖动浏览选中区间。
    private var isBrowsingSelection = false

    /// 双指缩放开始时记录的可视范围下界，用于避免累计缩放误差。
    private var pinchStartMinX: TimeInterval = 0
    /// 双指缩放开始时记录的可视范围上界。
    private var pinchStartMaxX: TimeInterval = 0
    /// 双指缩放开始时的锚点；该位置对应的时间在缩放期间保持不变。
    private var pinchAnchorPoint: CGPoint = .zero

    /// 驱动平移惯性逐帧更新的 DisplayLink。
    private var decelerationDisplayLink: CADisplayLink?
    /// 当前惯性横向速度，单位为 pt/s。
    private var decelerationVelocityX: CGFloat = 0
    /// 上一帧惯性回调的系统时间戳，用于计算真实帧间隔。
    private var lastDecelerationTimestamp: CFTimeInterval = 0
    /// 触发惯性所需的最小离手速度，单位为 pt/s。
    private let decelerationStartVelocityThreshold: CGFloat = 120
    /// 惯性速度低于该值时停止逐帧更新，单位为 pt/s。
    private let decelerationStopVelocityThreshold: CGFloat = 5

    /// 驱动状态块从左到右显示的加载动画 DisplayLink。
    private var loadAnimationDisplayLink: CADisplayLink?
    /// 加载动画首帧的系统时间戳，用于计算已播放时长。
    private var loadAnimationStartTimestamp: CFTimeInterval = 0
    /// 加载动画揭示进度，取值范围为 0...1。
    private var loadAnimationProgress: CGFloat = 1

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

    /// View 释放时停止 DisplayLink，避免惯性回调继续持有已经销毁的视图。
    deinit {
        stopDeceleration()
        stopLoadAnimation(finish: false)
    }

    /// 系统触发重绘时调用；View 负责准备数据，真正的路径绘制交给 Drawer。
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let visibleRange else { return }
        // 选中区间完全移出可视窗口时只隐藏 tooltip，保留选中状态以便移回后恢复显示。
        let visibleSelectedRange = selectedRange.flatMap { range in
            isRangeVisible(range, in: visibleRange) ? range : nil
        }
        drawer.draw(
            context: context,
            bounds: bounds,
            model: chartModel,
            visibleRange: visibleRange,
            blocks: stateBlocks,
            selectedRange: visibleSelectedRange,
            revealProgress: loadAnimationProgress
        )
    }

    /// 外部主动设置当前显示窗口时调用，不触发用户交互语义。
    func changeXRange(min: TimeInterval, max: TimeInterval) {
        updateXRange(min: min, max: max, isUserInteraction: false)
    }

    /// 模型内容发生变化后重新排序、归一化并生成可绘制状态块。
    func reloadData() {
        // 所有区间计算都依赖时间顺序，先统一排序再处理。
        let sortedPoints = chartModel.points.sorted { $0.x < $1.x }
        chartModel.points = sortedPoints

        guard let range = makeDataRange(points: sortedPoints) else {
            stopLoadAnimation(finish: false)
            dataRange = nil
            visibleRange = nil
            stateBlocks = []
            activeRanges = []
            selectedRange = nil
            loadAnimationProgress = 1
            setNeedsDisplay()
            return
        }

        loadAnimationProgress = chartModel.enableLoadAnimation ? 0 : 1
        dataRange = range
        selectedRange = nil
        let shouldUseExistingRange = chartModel.minX < chartModel.maxX
        let minX = shouldUseExistingRange ? chartModel.minX : range.lowerBound
        let maxX = shouldUseExistingRange ? chartModel.maxX : range.upperBound
        updateXRange(min: minX, max: maxX, isUserInteraction: false)
        startLoadAnimationIfNeeded()
    }

    /// 初始化 View 的基础显示属性和点击、平移、缩放手势。
    private func setupView() {
        backgroundColor = chartModel.backgroundColor
        isOpaque = true
        contentMode = .redraw
        isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinch)
    }

    /// 手指直接触摸图表时停止惯性，避免手势和 DisplayLink 同时修改窗口。
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopLoadAnimation(finish: true)
        stopDeceleration()
        super.touchesBegan(touches, with: event)
    }

    /// 只让横向滑动进入平移逻辑，竖向手势交给外层 ScrollView 等容器处理。
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, pan.view == self else {
            return true
        }
        guard chartModel.enablePan else { return false }
        let velocity = pan.velocity(in: self)
        return abs(velocity.x) > abs(velocity.y)
    }

    /// 统一更新显示窗口，并按模型配置把窗口限制在允许范围内。
    private func updateXRange(min: TimeInterval, max: TimeInterval, isUserInteraction: Bool) {
        guard min < max else { return }
        let range = adjustedVisibleRange(min: min, max: max)
        chartModel.minX = range.lowerBound
        chartModel.maxX = range.upperBound
        visibleRange = range
        rebuildVisibleBlocks()
        backgroundColor = chartModel.backgroundColor
        setNeedsDisplay()
    }

    /// 按 XRangeType、最小缩放跨度和最大缩放跨度修正传入窗口。
    private func adjustedVisibleRange(min: TimeInterval, max: TimeInterval) -> Range<TimeInterval> {
        var lower = min
        var upper = max
        var duration = upper - lower

        if duration < chartModel.minimumVisibleDuration {
            let center = (lower + upper) * 0.5
            duration = chartModel.minimumVisibleDuration
            lower = center - duration * 0.5
            upper = center + duration * 0.5
        }

        if let maximumVisibleDuration = chartModel.maximumVisibleDuration,
           duration > maximumVisibleDuration {
            let center = (lower + upper) * 0.5
            duration = maximumVisibleDuration
            lower = center - duration * 0.5
            upper = center + duration * 0.5
        }

        switch chartModel.XRangeType {
        case .unlimited:
            break
        case .limitedByData:
            guard let dataRange else { break }
            if duration >= dataRange.upperBound - dataRange.lowerBound {
                return dataRange
            }
            if lower < dataRange.lowerBound {
                upper += dataRange.lowerBound - lower
                lower = dataRange.lowerBound
            }
            if upper > dataRange.upperBound {
                lower -= upper - dataRange.upperBound
                upper = dataRange.upperBound
            }
        case .limited(let minX, let maxX):
            let allowedRange = minX..<maxX
            guard allowedRange.lowerBound < allowedRange.upperBound else { break }
            if duration >= allowedRange.upperBound - allowedRange.lowerBound {
                return allowedRange
            }
            if lower < allowedRange.lowerBound {
                upper += allowedRange.lowerBound - lower
                lower = allowedRange.lowerBound
            }
            if upper > allowedRange.upperBound {
                lower -= upper - allowedRange.upperBound
                upper = allowedRange.upperBound
            }
        case .distanceByNow(let distance):
            let now = Date().timeIntervalSince1970
            let allowedRange = (now - distance)..<now
            if duration >= allowedRange.upperBound - allowedRange.lowerBound {
                return allowedRange
            }
            if lower < allowedRange.lowerBound {
                upper += allowedRange.lowerBound - lower
                lower = allowedRange.lowerBound
            }
            if upper > allowedRange.upperBound {
                lower -= upper - allowedRange.upperBound
                upper = allowedRange.upperBound
            }
        }

        return lower..<upper
    }

    /// 根据当前窗口重新生成绘制区间和可选中的 y=1 区间。
    private func rebuildVisibleBlocks() {
        guard let visibleRange else {
            stateBlocks = []
            activeRanges = []
            selectedRange = nil
            return
        }

        // 多个连续相同 y 值只生成一个状态块，避免内部出现多余接缝和圆角。
        stateBlocks = makeStateBlocks(points: chartModel.points, visibleRange: visibleRange)
        activeRanges = stateBlocks.filter { $0.value == 1 }.map(\.range)
    }

    /// 处理点击选中逻辑；选中距离触点时间最近的 y=1 区间。
    @objc private func didTap(_ gesture: UITapGestureRecognizer) {
        stopLoadAnimation(finish: true)
        stopDeceleration()
        guard chartModel.showsSelection else { return }
        let location = gesture.location(in: self)
        if isPointInsideSelectedTooltip(location) {
            selectedRange = nil
            setNeedsDisplay()
            return
        }
        // 点击任意图表位置时，吸附到最近的 y=1 区间。
        updateSelection(at: location, clearWhenMiss: true)
    }

    /// 处理左右平移手势，手指松开后按配置决定是否启动惯性。
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard chartModel.enablePan else { return }
        switch gesture.state {
        case .began:
            stopLoadAnimation(finish: true)
            stopDeceleration()
            // 和 LineChartView 一样：只有按在 tooltip 框内部，拖动才用于浏览 tooltip。
            isBrowsingSelection = isPointInsideSelectedTooltip(gesture.location(in: self))
            if isBrowsingSelection {
                updateSelection(at: gesture.location(in: self), clearWhenMiss: false)
            }
        case .changed:
            if isBrowsingSelection {
                updateSelection(at: gesture.location(in: self), clearWhenMiss: false)
                return
            }
            let translation = gesture.translation(in: self)
            gesture.setTranslation(.zero, in: self)
            _ = shiftVisibleRange(by: dataOffsetFromViewTranslation(translation.x))
        case .ended:
            if isBrowsingSelection {
                // 使用手势结束位置完成最后一次吸附，避免终点未触发 changed 时停在前一个区间。
                updateSelection(at: gesture.location(in: self), clearWhenMiss: false)
                isBrowsingSelection = false
                return
            }
            startDeceleration(with: gesture.velocity(in: self).x)
        case .cancelled, .failed:
            isBrowsingSelection = false
            stopDeceleration()
        default:
            break
        }
    }

    /// 根据触点时间选择最近的 y=1 区间；没有可选区间时可选择清空状态。
    private func updateSelection(at location: CGPoint, clearWhenMiss: Bool) {
        guard let visibleRange else { return }
        let timestamp = drawer.timestamp(
            at: location.x,
            bounds: bounds,
            model: chartModel,
            visibleRange: visibleRange
        )
        if let range = nearestActiveRange(to: timestamp) {
            selectedRange = range
        } else if clearWhenMiss {
            selectedRange = nil
        }
        setNeedsDisplay()
    }

    /// 返回触点时间距离最近的 y=1 区间；区间内距离为 0，区间外按最近边界计算。
    private func nearestActiveRange(to timestamp: TimeInterval) -> Range<TimeInterval>? {
        var nearestRange: Range<TimeInterval>?
        var nearestDistance = TimeInterval.greatestFiniteMagnitude

        for range in activeRanges {
            let distance: TimeInterval
            if timestamp < range.lowerBound {
                distance = range.lowerBound - timestamp
            } else if timestamp > range.upperBound {
                distance = timestamp - range.upperBound
            } else {
                distance = 0
            }

            // 距离相同时保留时间更早的区间，避免临界位置来回跳变。
            if distance < nearestDistance {
                nearestDistance = distance
                nearestRange = range
            }
        }

        return nearestRange
    }

    /// 判断触点是否落在当前 tooltip 内；只有命中 tooltip 才接管拖动浏览。
    private func isPointInsideSelectedTooltip(_ point: CGPoint) -> Bool {
        guard chartModel.showsSelection,
              let visibleRange,
              let selectedRange,
              isRangeVisible(selectedRange, in: visibleRange) else {
            return false
        }
        let rect = drawer.tooltipRect(
            bounds: bounds,
            model: chartModel,
            visibleRange: visibleRange,
            range: selectedRange
        )
        return rect.contains(point)
    }

    /// 判断状态区间是否至少有一部分位于当前可视时间范围内。
    private func isRangeVisible(
        _ range: Range<TimeInterval>,
        in visibleRange: Range<TimeInterval>
    ) -> Bool {
        range.lowerBound < visibleRange.upperBound && range.upperBound > visibleRange.lowerBound
    }

    /// 处理双指缩放，缩放中心固定在手势开始的位置。
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard chartModel.enablePinch, let visibleRange else { return }
        switch gesture.state {
        case .began:
            stopLoadAnimation(finish: true)
            stopDeceleration()
            pinchAnchorPoint = gesture.location(in: self)
            pinchStartMinX = visibleRange.lowerBound
            pinchStartMaxX = visibleRange.upperBound
        case .changed:
            guard gesture.scale > 0 else { return }
            let anchorX = drawer.timestamp(
                at: pinchAnchorPoint.x,
                bounds: bounds,
                model: chartModel,
                visibleRange: pinchStartMinX..<pinchStartMaxX
            )
            let newMinX = anchorX - (anchorX - pinchStartMinX) / TimeInterval(gesture.scale)
            let newMaxX = anchorX + (pinchStartMaxX - anchorX) / TimeInterval(gesture.scale)
            updateXRange(min: newMinX, max: newMaxX, isUserInteraction: true)
        case .cancelled, .failed:
            stopDeceleration()
        default:
            break
        }
    }

    /// 将手指在 View 上移动的像素距离转换为 X 轴数据距离。
    private func dataOffsetFromViewTranslation(_ translationX: CGFloat) -> TimeInterval {
        guard let visibleRange, bounds.width > 0 else { return 0 }
        let plotWidth = max(1, bounds.width - chartModel.contentInsets.left - chartModel.contentInsets.right)
        let visibleDuration = visibleRange.upperBound - visibleRange.lowerBound
        return TimeInterval((translationX / plotWidth) * CGFloat(visibleDuration))
    }

    /// 按指定数据偏移量移动当前可视窗口。
    @discardableResult
    private func shiftVisibleRange(by dataOffset: TimeInterval) -> Bool {
        guard let visibleRange else { return false }
        let oldRange = visibleRange
        updateXRange(
            min: oldRange.lowerBound - dataOffset,
            max: oldRange.upperBound - dataOffset,
            isUserInteraction: true
        )
        return oldRange.lowerBound != chartModel.minX || oldRange.upperBound != chartModel.maxX
    }

    /// 根据手指离开时的速度启动横向惯性滑动。
    private func startDeceleration(with velocityX: CGFloat) {
        stopDeceleration()
        guard chartModel.enableDeceleration else { return }
        guard abs(velocityX) > decelerationStartVelocityThreshold else { return }
        decelerationVelocityX = velocityX
        lastDecelerationTimestamp = 0
        let displayLink = CADisplayLink(target: self, selector: #selector(handleDecelerationTick(_:)))
        displayLink.add(to: .main, forMode: .common)
        decelerationDisplayLink = displayLink
    }

    /// 停止当前惯性滑动，并清空速度状态。
    private func stopDeceleration() {
        decelerationDisplayLink?.invalidate()
        decelerationDisplayLink = nil
        decelerationVelocityX = 0
        lastDecelerationTimestamp = 0
    }

    /// 根据模型配置启动从左到右的加载动画。
    private func startLoadAnimationIfNeeded() {
        stopLoadAnimation(finish: false)
        guard chartModel.enableLoadAnimation,
              chartModel.loadAnimationDuration > 0,
              visibleRange != nil else {
            loadAnimationProgress = 1
            setNeedsDisplay()
            return
        }

        loadAnimationProgress = 0
        loadAnimationStartTimestamp = 0
        let displayLink = CADisplayLink(target: self, selector: #selector(handleLoadAnimationTick(_:)))
        displayLink.add(to: .main, forMode: .common)
        loadAnimationDisplayLink = displayLink
        setNeedsDisplay()
    }

    /// 停止加载动画；finish 为 true 时直接展示完整图形。
    private func stopLoadAnimation(finish: Bool) {
        loadAnimationDisplayLink?.invalidate()
        loadAnimationDisplayLink = nil
        loadAnimationStartTimestamp = 0
        if finish {
            loadAnimationProgress = 1
            setNeedsDisplay()
        }
    }

    /// 每一帧推进加载动画进度，进度达到 1 后停止 DisplayLink。
    @objc private func handleLoadAnimationTick(_ displayLink: CADisplayLink) {
        if loadAnimationStartTimestamp == 0 {
            loadAnimationStartTimestamp = displayLink.timestamp
            return
        }

        let elapsed = displayLink.timestamp - loadAnimationStartTimestamp
        let progress = elapsed / chartModel.loadAnimationDuration
        loadAnimationProgress = CGFloat(min(1, max(0, progress)))
        setNeedsDisplay()

        if loadAnimationProgress >= 1 {
            stopLoadAnimation(finish: true)
        }
    }

    /// 每一帧根据剩余速度继续移动窗口，并模拟 UIScrollView 的减速曲线。
    @objc private func handleDecelerationTick(_ displayLink: CADisplayLink) {
        if lastDecelerationTimestamp == 0 {
            lastDecelerationTimestamp = displayLink.timestamp
            return
        }

        let deltaTime = displayLink.timestamp - lastDecelerationTimestamp
        lastDecelerationTimestamp = displayLink.timestamp

        let didMove = shiftVisibleRange(
            by: dataOffsetFromViewTranslation(decelerationVelocityX * CGFloat(deltaTime))
        )
        let rate = CGFloat(pow(Double(UIScrollView.DecelerationRate.normal.rawValue), deltaTime * 1000))
        decelerationVelocityX *= rate

        if !didMove || abs(decelerationVelocityX) < decelerationStopVelocityThreshold {
            stopDeceleration()
        }
    }

    /// 根据数据首尾时间生成完整数据范围，单点数据会给出一个最小可视跨度。
    private func makeDataRange(points: [BinaryTimelinePointModel]) -> Range<TimeInterval>? {
        guard let first = points.first, let last = points.last else { return nil }
        let lower: TimeInterval
        let upper: TimeInterval
        switch chartModel.XRangeType {
        case .limited(let minX, let maxX) where minX < maxX:
            lower = minX
            upper = maxX
        case .distanceByNow(let distance) where distance > 0:
            upper = Date().timeIntervalSince1970
            lower = upper - distance
        default:
            lower = first.x
            upper = last.x
        }
        guard upper > lower else {
            return lower..<(lower + chartModel.minimumVisibleDuration)
        }
        return lower..<upper
    }

    /// 将当前可视窗口内的数据点合并为连续状态块，减少绘制时的重复路径和多余圆角。
    private func makeStateBlocks(
        points: [BinaryTimelinePointModel],
        visibleRange: Range<TimeInterval>
    ) -> [BinaryTimelineStateBlock] {
        // 状态图形最多绘制到当前时间；可视窗口中超出当前时间的部分保留为空白。
        let drawableUpperBound = min(visibleRange.upperBound, Date().timeIntervalSince1970)
        guard drawableUpperBound > visibleRange.lowerBound else { return [] }
        let drawableRange = visibleRange.lowerBound..<drawableUpperBound
        let changes = points.filter { $0.x > drawableRange.lowerBound && $0.x < drawableRange.upperBound }
        var blocks: [BinaryTimelineStateBlock] = []
        var start = drawableRange.lowerBound
        var value = points.last(where: { $0.x <= drawableRange.lowerBound })?.y ?? 0
        // 只有状态改变时才结束当前块，重复的相同状态点不会拆分区间。
        for point in changes where point.y != value {
            if point.x > start {
                blocks.append(BinaryTimelineStateBlock(start: start, end: point.x, value: value))
            }
            start = point.x
            value = point.y
        }
        // 最后一个有效状态只持续到可绘制上限，不延伸进入未来时间区域。
        if drawableRange.upperBound > start {
            blocks.append(BinaryTimelineStateBlock(start: start, end: drawableRange.upperBound, value: value))
        }
        return blocks
    }
}
