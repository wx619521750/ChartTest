import UIKit

/// 负责二值时间轴的所有坐标计算与 Core Graphics 绘制。
final class BinaryTimelineDrawer {
    /// 按背景、状态块、坐标轴、选中提示的顺序完成一次完整绘制。
    func draw(
        context: CGContext,
        bounds: CGRect,
        model: BinaryTimelineChartModel,
        dayRange: Range<TimeInterval>,
        blocks: [BinaryTimelineStateBlock],
        selectedRange: Range<TimeInterval>?
    ) {
        model.backgroundColor.setFill()
        context.fill(bounds)

        // y=1 位于上方，y=0 按配置的中心距位于下方。
        let plotRect = plotRect(in: bounds, model: model)
        let activeY = plotRect.minY + model.blockHeight * 0.5
        let inactiveY = activeY + model.stateVerticalDistance

        drawStateBlocks(
            context: context,
            model: model,
            dayRange: dayRange,
            blocks: blocks,
            plotRect: plotRect,
            activeY: activeY,
            inactiveY: inactiveY
        )
        drawAxis(bounds: bounds, model: model, dayRange: dayRange, plotRect: plotRect)

        if model.showsSelection, let selectedRange {
            drawSelection(
                context: context,
                bounds: bounds,
                model: model,
                dayRange: dayRange,
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
        dayRange: Range<TimeInterval>
    ) -> TimeInterval {
        let plotRect = plotRect(in: bounds, model: model)
        // 先把点击点转换成 0...1 的横向进度，超出绘图区的点击会吸附到首尾。
        let progress = min(1, max(0, (locationX - plotRect.minX) / max(plotRect.width, 1)))
        // 再把横向进度映射回当天的真实时间戳。
        return dayRange.lowerBound + TimeInterval(progress) * (dayRange.upperBound - dayRange.lowerBound)
    }

    /// 绘制所有红灰状态块，并在状态切换处绘制竖向渐变连接线。
    private func drawStateBlocks(
        context: CGContext,
        model: BinaryTimelineChartModel,
        dayRange: Range<TimeInterval>,
        blocks: [BinaryTimelineStateBlock],
        plotRect: CGRect,
        activeY: CGFloat,
        inactiveY: CGFloat
    ) {
        guard !blocks.isEmpty else { return }
        context.saveGState()

        // 先画竖向渐变连接线，随后色块覆盖连接线端点，保证交界处无圆头。
        for index in 0..<(blocks.count - 1) {
            let x = xPosition(blocks[index].end, dayRange: dayRange, plotRect: plotRect)
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
                xPosition(block.start, dayRange: dayRange, plotRect: plotRect)
                    - (index > 0 ? boundaryOverlap : 0)
            )
            let endX = min(
                plotRect.maxX,
                xPosition(block.end, dayRange: dayRange, plotRect: plotRect)
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
        dayRange: Range<TimeInterval>,
        plotRect: CGRect
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: model.axisFont,
            .foregroundColor: model.axisTextColor
        ]
        let labelY = bounds.height - model.axisLabelBottom
        for hour in model.axisHours {
            let text = String(format: "%02d:00", hour)
            let size = text.size(withAttributes: attributes)
            let timestamp = dayRange.lowerBound + TimeInterval(hour * 3600)
            let x = xPosition(timestamp, dayRange: dayRange, plotRect: plotRect)
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
        dayRange: Range<TimeInterval>,
        range: Range<TimeInterval>,
        plotRect: CGRect,
        activeY: CGFloat
    ) {
        // 提示框和虚线锚定在选中 y=1 区间的时间中心。
        let centerX = xPosition(
            (range.lowerBound + range.upperBound) * 0.5,
            dayRange: dayRange,
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
        dayRange: Range<TimeInterval>,
        plotRect: CGRect
    ) -> CGFloat {
        // 将一天内的时间进度线性映射到绘图区，并裁剪到 00:00...24:00。
        let progress = (timestamp - dayRange.lowerBound) / (dayRange.upperBound - dayRange.lowerBound)
        return plotRect.minX + CGFloat(min(1, max(0, progress))) * plotRect.width
    }

    /// 将时间戳格式化为提示框中使用的 HH:mm 文本。
    private func timeString(_ timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }
}
