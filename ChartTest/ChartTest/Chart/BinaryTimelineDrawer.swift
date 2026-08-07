import UIKit

/// 负责二值时间轴的所有坐标计算与 Core Graphics 绘制。
final class BinaryTimelineDrawer {
    /// 按背景、状态块、坐标轴、选中提示的顺序完成一次完整绘制。
    func draw(
        context: CGContext,
        bounds: CGRect,
        model: BinaryTimelineChartModel,
        visibleRange: Range<TimeInterval>,
        blocks: [BinaryTimelineStateBlock],
        selectedRange: Range<TimeInterval>?,
        revealProgress: CGFloat = 1
    ) {
        model.backgroundColor.setFill()
        context.fill(bounds)

        // y=1 位于上方，y=0 位于下方；两条状态轨道整体在 contentInsets 对应的绘图区内垂直居中。
        let plotRect = plotRect(in: bounds, model: model)
        let totalStateHeight = model.stateVerticalDistance + model.blockHeight
        let activeY = plotRect.midY - totalStateHeight * 0.5 + model.blockHeight * 0.5
        let inactiveY = activeY + model.stateVerticalDistance

        drawStateBlocks(
            context: context,
            model: model,
            visibleRange: visibleRange,
            blocks: blocks,
            plotRect: plotRect,
            activeY: activeY,
            inactiveY: inactiveY,
            revealProgress: revealProgress
        )
        drawAxis(bounds: bounds, model: model, visibleRange: visibleRange, plotRect: plotRect)

        if model.showsSelection, revealProgress >= 1, let selectedRange {
            drawSelection(
                context: context,
                bounds: bounds,
                model: model,
                visibleRange: visibleRange,
                range: selectedRange,
                plotRect: plotRect,
                activeY: activeY
            )
        }
    }

    /// 将点击位置的 X 坐标反算为当天时间戳，并限制在绘图区范围内。
    func timestamp(
        at locationX: CGFloat,
        bounds: CGRect,
        model: BinaryTimelineChartModel,
        visibleRange: Range<TimeInterval>
    ) -> TimeInterval {
        let plotRect = plotRect(in: bounds, model: model)
        // 先把点击点转换成 0...1 的横向进度，超出绘图区的点击会吸附到首尾。
        let progress = min(1, max(0, (locationX - plotRect.minX) / max(plotRect.width, 1)))
        // 再把横向进度映射回当前可视窗口的真实时间戳。
        return visibleRange.lowerBound + TimeInterval(progress) * (visibleRange.upperBound - visibleRange.lowerBound)
    }

    /// 绘制所有红灰状态块，并在状态切换处绘制竖向渐变连接线。
    private func drawStateBlocks(
        context: CGContext,
        model: BinaryTimelineChartModel,
        visibleRange: Range<TimeInterval>,
        blocks: [BinaryTimelineStateBlock],
        plotRect: CGRect,
        activeY: CGFloat,
        inactiveY: CGFloat,
        revealProgress: CGFloat
    ) {
        guard !blocks.isEmpty else { return }
        context.saveGState()
        let progress = min(1, max(0, revealProgress))
        guard progress > 0 else {
            context.restoreGState()
            return
        }

        // 加载动画只裁剪状态图形区域，坐标轴保持完整显示。
        if progress < 1 {
            let revealRect = CGRect(
                x: plotRect.minX,
                y: 0,
                width: plotRect.width * progress,
                height: plotRect.maxY + model.blockHeight
            )
            context.clip(to: revealRect)
        }

        // 先画竖向渐变连接线，随后色块覆盖连接线端点，保证交界处无圆头。
        for index in 0..<(blocks.count - 1) {
            let x = xPosition(blocks[index].end, visibleRange: visibleRange, plotRect: plotRect)
            drawTransitionGradient(
                context: context,
                model: model,
                x: x,
                activeY: activeY,
                inactiveY: inactiveY
            )
        }

        for index in blocks.indices {
            let block = blocks[index]
            // 连接线以状态切换 X 为中心。相邻色块各扩展半个连接线宽，
            // 使连接线完整落在两个色块共同覆盖的 X 范围内。
            let boundaryOverlap = model.connectorWidth * 0.5
            let startX = max(
                plotRect.minX,
                xPosition(block.start, visibleRange: visibleRange, plotRect: plotRect)
                    - (index > 0 ? boundaryOverlap : 0)
            )
            let endX = min(
                plotRect.maxX,
                xPosition(block.end, visibleRange: visibleRange, plotRect: plotRect)
                    + (index + 1 < blocks.count ? boundaryOverlap : 0)
            )
            let blockWidth = max(0, endX - startX)
            guard blockWidth > 0 else { continue }

            // y=1 使用红色上轨，y=0 使用灰色下轨。
            let centerY = block.value == 1 ? activeY : inactiveY
            let blockRect = CGRect(
                x: startX,
                y: centerY - model.blockHeight * 0.5,
                width: blockWidth,
                height: model.blockHeight
            )
            // 短色块的圆角不能超过宽度的一半，否则路径会发生形变。
            let radius = min(model.maximumCornerRadius, blockWidth * 0.5)
            let corners = roundedCorners(
                value: block.value,
                hasLeftConnector: index > 0,
                hasRightConnector: index + 1 < blocks.count
            )
            (block.value == 1 ? model.activeColor : model.inactiveColor).setFill()
            UIBezierPath(
                roundedRect: blockRect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            ).fill()
        }
        context.restoreGState()
    }

    /// 绘制红色块和灰色块之间的竖向渐变连接区域。
    private func drawTransitionGradient(
        context: CGContext,
        model: BinaryTimelineChartModel,
        x: CGFloat,
        activeY: CGFloat,
        inactiveY: CGFloat
    ) {
        // 渐变方向固定为上方红色到下方灰色，与状态变化方向无关。
        let colors = [model.activeColor.cgColor, model.inactiveColor.cgColor] as CFArray
        guard model.connectorWidth > 0,
              let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 1]
              ) else { return }

        // 连接线顶端严格贴合红块下边缘，底端严格贴合灰块上边缘。
        let top = min(activeY, inactiveY) + model.blockHeight * 0.5
        let bottom = max(activeY, inactiveY) - model.blockHeight * 0.5
        guard bottom > top else { return }

        // 连接线以状态切换点为中心，左右各占一半宽度。
        let rect = CGRect(
            x: x - model.connectorWidth * 0.5,
            y: top,
            width: model.connectorWidth,
            height: bottom - top
        )
        context.saveGState()
        context.clip(to: rect)
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )
        context.restoreGState()
    }

    /// 根据状态值和左右连接关系，计算当前色块需要保留圆角的位置。
    private func roundedCorners(
        value: Int,
        hasLeftConnector: Bool,
        hasRightConnector: Bool
    ) -> UIRectCorner {
        if value == 1 {
            // 红块底部与连接线接触，因此只有顶部两个角允许圆角。
            return [.topLeft, .topRight]
        }

        // 灰块底角始终可圆；与连接线接触一侧的顶部角必须保持直角。
        var corners: UIRectCorner = [.bottomLeft, .bottomRight]
        if !hasLeftConnector { corners.insert(.topLeft) }
        if !hasRightConnector { corners.insert(.topRight) }
        return corners
    }

    /// 绘制底部小时刻度文本。
    private func drawAxis(
        bounds: CGRect,
        model: BinaryTimelineChartModel,
        visibleRange: Range<TimeInterval>,
        plotRect: CGRect
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: model.axisFont,
            .foregroundColor: model.axisTextColor
        ]
        let labelY = bounds.height - model.axisLabelBottom
        let axisInfo = dateAdaptiveStamps(visibleRange: visibleRange)
        for timestamp in axisInfo.stamps {
            let text = dateString(timestamp, format: axisInfo.format)
            let size = text.size(withAttributes: attributes)
            let x = xPosition(timestamp, visibleRange: visibleRange, plotRect: plotRect)
            // 中间刻度按时间点居中，首尾刻度会限制在 View 内避免文本被截断。
            let originX = min(bounds.width - size.width, max(0, x - size.width * 0.5))
            text.draw(at: CGPoint(x: originX, y: labelY), withAttributes: attributes)
        }
    }

    /// 绘制选中 y=1 区间对应的虚线、提示框和提示文本。
    private func drawSelection(
        context: CGContext,
        bounds: CGRect,
        model: BinaryTimelineChartModel,
        visibleRange: Range<TimeInterval>,
        range: Range<TimeInterval>,
        plotRect: CGRect,
        activeY: CGFloat
    ) {
        // 提示框和虚线锚定在选中 y=1 区间的时间中心。
        let centerX = xPosition(
            (range.lowerBound + range.upperBound) * 0.5,
            visibleRange: visibleRange,
            plotRect: plotRect
        )
        // 区间时长直接由两个 Unix 时间戳相减得到。
        let duration = max(0, Int(range.upperBound - range.lowerBound))
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let durationText = hours > 0 ? "Duration: \(hours)h \(minutes)min" : "Duration: \(minutes)min"
        let timeText = "\(timeString(range.lowerBound)) - \(timeString(range.upperBound))"

        let font = model.tooltipFont
        let lineHeight = font.lineHeight
        let textWidth = max(
            durationText.size(withAttributes: [.font: font]).width,
            timeText.size(withAttributes: [.font: font]).width
        )
        let tooltipSize = CGSize(
            width: textWidth + model.tooltipHorizontalPadding * 2,
            height: lineHeight * 2 + model.tooltipVerticalPadding * 2
        )
        // 提示框优先相对锚点居中，靠近左右边缘时整体收回 View 内。
        let tooltipX = min(
            bounds.width - tooltipSize.width - 8,
            max(8, centerX - tooltipSize.width * 0.5)
        )
        let tooltipRect = CGRect(
            origin: CGPoint(x: tooltipX, y: model.tooltipTop),
            size: tooltipSize
        )

        // 虚线先绘制，提示框后绘制，从而隐藏虚线进入提示框内部的部分。
        context.saveGState()
        context.setStrokeColor(model.selectionLineColor.cgColor)
        context.setLineWidth(model.selectionLineWidth)
        context.setLineDash(phase: 0, lengths: model.selectionLineDash)
        context.move(to: CGPoint(x: centerX, y: tooltipRect.maxY))
        context.addLine(to: CGPoint(x: centerX, y: activeY - model.blockHeight * 0.5))
        context.strokePath()
        context.restoreGState()

        model.tooltipBackgroundColor.setFill()
        UIBezierPath(roundedRect: tooltipRect, cornerRadius: model.tooltipCornerRadius).fill()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: model.tooltipTextColor
        ]
        drawCentered(
            durationText,
            y: tooltipRect.minY + model.tooltipVerticalPadding,
            rect: tooltipRect,
            attributes: attributes
        )
        drawCentered(
            timeText,
            y: tooltipRect.minY + model.tooltipVerticalPadding + lineHeight,
            rect: tooltipRect,
            attributes: attributes
        )
    }

    /// 在指定矩形内按水平居中的方式绘制一行文本。
    private func drawCentered(
        _ text: String,
        y: CGFloat,
        rect: CGRect,
        attributes: [NSAttributedString.Key: Any]
    ) {
        let size = text.size(withAttributes: attributes)
        text.draw(at: CGPoint(x: rect.midX - size.width * 0.5, y: y), withAttributes: attributes)
    }

    /// 根据模型边距计算绘图区，所有时间到 X 坐标的映射都基于这个区域。
    private func plotRect(in bounds: CGRect, model: BinaryTimelineChartModel) -> CGRect {
        // 所有曲线和刻度的水平坐标都基于同一个绘图区，保证点击与绘制一致。
        CGRect(
            x: model.contentInsets.left,
            y: model.contentInsets.top,
            width: max(0, bounds.width - model.contentInsets.left - model.contentInsets.right),
            height: max(0, bounds.height - model.contentInsets.top - model.contentInsets.bottom)
        )
    }

    /// 将时间戳映射为绘图区内的 X 坐标。
    private func xPosition(
        _ timestamp: TimeInterval,
        visibleRange: Range<TimeInterval>,
        plotRect: CGRect
    ) -> CGFloat {
        // 将当前窗口内的时间进度线性映射到绘图区，并裁剪到窗口首尾。
        let progress = (timestamp - visibleRange.lowerBound) / (visibleRange.upperBound - visibleRange.lowerBound)
        return plotRect.minX + CGFloat(min(1, max(0, progress))) * plotRect.width
    }

    /// 参照 LineChartView 的逻辑，根据当前时间跨度生成自适应刻度和日期格式。
    private func dateAdaptiveStamps(visibleRange: Range<TimeInterval>) -> (stamps: [TimeInterval], format: String) {
        let range = visibleRange.upperBound - visibleRange.lowerBound
        if range <= 1800 {
            return (alignedTimestamps(start: visibleRange.lowerBound, end: visibleRange.upperBound, step: .minutes(5)), "HH:mm")
        } else if range <= 3600 {
            return (alignedTimestamps(start: visibleRange.lowerBound, end: visibleRange.upperBound, step: .minutes(10)), "HH:mm")
        } else if range <= 3600 * 6 {
            return (alignedTimestamps(start: visibleRange.lowerBound, end: visibleRange.upperBound, step: .hours(1)), "HH:mm")
        } else if range <= 3600 * 12 {
            return (alignedTimestamps(start: visibleRange.lowerBound, end: visibleRange.upperBound, step: .hours(2)), "HH:mm")
        } else if range <= 3600 * 24 {
            return (alignedTimestamps(start: visibleRange.lowerBound, end: visibleRange.upperBound, step: .hours(4)), "HH:mm")
        } else if range <= 3600 * 24 * 7 {
            return (alignedTimestamps(start: visibleRange.lowerBound, end: visibleRange.upperBound, step: .days(1)), "EEE")
        } else if range <= 3600 * 24 * 14 {
            return (alignedTimestamps(start: visibleRange.lowerBound, end: visibleRange.upperBound, step: .days(2)), "MM/dd")
        } else if range <= 3600 * 24 * 30 {
            return (alignedTimestamps(start: visibleRange.lowerBound, end: visibleRange.upperBound, step: .days(5)), "MM/dd")
        } else if range <= 3600 * 24 * 30 * 6 {
            return (alignedTimestamps(start: visibleRange.lowerBound, end: visibleRange.upperBound, step: .months(1)), "MMM")
        } else if range <= 3600 * 24 * 30 * 12 {
            return (alignedTimestamps(start: visibleRange.lowerBound, end: visibleRange.upperBound, step: .months(2)), "MMM")
        } else {
            let monthStep = max(1, Int(range / 6 / (3600 * 24 * 30)))
            return (alignedTimestamps(start: visibleRange.lowerBound, end: visibleRange.upperBound, step: .months(monthStep)), "MMM")
        }
    }

    /// 生成与自然时间边界对齐的刻度，例如整 10 分钟、整点、整天或整月。
    private func alignedTimestamps(
        start: TimeInterval,
        end: TimeInterval,
        step: BinaryTimelineTimeStep,
        calendar: Calendar = .current
    ) -> [TimeInterval] {
        guard start < end else { return [] }
        let startDate = Date(timeIntervalSince1970: start)
        let endDate = Date(timeIntervalSince1970: end)
        var current: Date?

        switch step {
        case .minutes(let minutes):
            var comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
            if let minute = comps.minute {
                let remainder = minute % minutes
                comps.minute = remainder == 0 ? minute : minute + (minutes - remainder)
            }
            comps.second = 0
            current = calendar.date(from: comps)
        case .hours(let hours):
            var comps = calendar.dateComponents([.year, .month, .day, .hour], from: startDate)
            if let hour = comps.hour {
                let remainder = hour % hours
                comps.hour = remainder == 0 ? hour : hour + (hours - remainder)
            }
            comps.minute = 0
            comps.second = 0
            current = calendar.date(from: comps)
        case .days(let days):
            var comps = calendar.dateComponents([.year, .month, .day], from: startDate)
            if let day = comps.day {
                let remainder = (day - 1) % days
                comps.day = remainder == 0 ? day : day + (days - remainder)
            }
            comps.hour = 0
            comps.minute = 0
            comps.second = 0
            current = calendar.date(from: comps)
        case .months(let months):
            var comps = calendar.dateComponents([.year, .month], from: startDate)
            if let month = comps.month {
                let remainder = (month - 1) % months
                comps.month = remainder == 0 ? month : month + (months - remainder)
            }
            comps.day = 1
            comps.hour = 0
            comps.minute = 0
            comps.second = 0
            current = calendar.date(from: comps)
        }

        guard var date = current else { return [] }
        while date < startDate {
            guard let next = calendar.date(byAdding: step.calendarComponent, value: step.value, to: date) else {
                return []
            }
            date = next
        }

        var result: [TimeInterval] = []
        while date <= endDate {
            result.append(date.timeIntervalSince1970)
            guard let next = calendar.date(byAdding: step.calendarComponent, value: step.value, to: date) else {
                break
            }
            date = next
        }
        return result
    }

    /// 按指定格式生成坐标轴文本。
    private func dateString(_ timestamp: TimeInterval, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    /// 将时间戳格式化为提示框中使用的 HH:mm 文本。
    private func timeString(_ timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }
}

/// BinaryTimelineDrawer 内部使用的自然时间步长。
private enum BinaryTimelineTimeStep {
    case minutes(Int)
    case hours(Int)
    case days(Int)
    case months(Int)
}

private extension BinaryTimelineTimeStep {
    var calendarComponent: Calendar.Component {
        switch self {
        case .minutes:
            return .minute
        case .hours:
            return .hour
        case .days:
            return .day
        case .months:
            return .month
        }
    }

    var value: Int {
        switch self {
        case .minutes(let value),
             .hours(let value),
             .days(let value),
             .months(let value):
            return value
        }
    }
}
