import UIKit

struct BinaryTimelinePoint {
    let timestamp: TimeInterval
    let value: Int

    init(timestamp: TimeInterval, value: Int) {
        self.timestamp = timestamp
        self.value = value == 0 ? 0 : 1
    }
}

final class BinaryTimelineChartView: UIView {
    private struct StateBlock {
        let start: TimeInterval
        let end: TimeInterval
        let value: Int
    }

    var points: [BinaryTimelinePoint] = [] {
        didSet {
            points.sort { $0.timestamp < $1.timestamp }
            selectedRangeIndex = activeRanges.indices.first
            setNeedsDisplay()
        }
    }

    var inactiveColor = UIColor(red: 0.89, green: 0.95, blue: 0.98, alpha: 1)
    var activeColor = UIColor(red: 0.98, green: 0.22, blue: 0.24, alpha: 1)
    var axisTextColor = UIColor(white: 0.48, alpha: 1)

    private var selectedRangeIndex: Int?
    private let calendar = Calendar.current

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        isOpaque = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap(_:))))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
        isOpaque = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap(_:))))
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let day = dayRange else { return }

        let horizontalInset: CGFloat = 12
        let plotRect = CGRect(
            x: horizontalInset,
            y: 74,
            width: bounds.width - horizontalInset * 2,
            height: max(70, bounds.height - 142)
        )
        let lineWidth: CGFloat = 18
        let activeY = plotRect.minY + lineWidth * 0.5
        let inactiveY = activeY + 36

        drawStateLine(
            context: context,
            day: day,
            inactiveY: inactiveY,
            activeY: activeY,
            lineWidth: lineWidth,
            plotRect: plotRect
        )
        drawAxis(day: day, plotRect: plotRect)
        drawSelection(context: context, day: day, activeY: activeY, plotRect: plotRect)
    }

    private func drawStateLine(
        context: CGContext,
        day: Range<TimeInterval>,
        inactiveY: CGFloat,
        activeY: CGFloat,
        lineWidth: CGFloat,
        plotRect: CGRect
    ) {
        let blocks = stateBlocks(in: day)
        guard !blocks.isEmpty else { return }

        context.saveGState()
        let connectorWidth: CGFloat = 1

        // Draw square-ended transition columns first so the horizontal blocks
        // cover their endpoints without introducing rounded connection vertices.
        for index in 0..<(blocks.count - 1) {
            let x = xPosition(blocks[index].end, day: day, plotRect: plotRect)
            drawTransitionGradient(
                context: context,
                x: x,
                activeY: activeY,
                inactiveY: inactiveY,
                blockHeight: lineWidth,
                width: connectorWidth
            )
        }

        for index in blocks.indices {
            let block = blocks[index]
            let boundaryOverlap = connectorWidth * 0.5
            let startX = max(
                plotRect.minX,
                xPosition(block.start, day: day, plotRect: plotRect) - (index > 0 ? boundaryOverlap : 0)
            )
            let endX = min(
                plotRect.maxX,
                xPosition(block.end, day: day, plotRect: plotRect)
                    + (index + 1 < blocks.count ? boundaryOverlap : 0)
            )
            let y = block.value == 1 ? activeY : inactiveY
            let blockWidth = max(0, endX - startX)
            guard blockWidth > 0 else { continue }
            let cornerRadius = min(4, blockWidth * 0.5)
            let blockRect = CGRect(
                x: startX,
                y: y - lineWidth * 0.5,
                width: blockWidth,
                height: lineWidth
            )
            (block.value == 1 ? activeColor : inactiveColor).setFill()
            let corners = roundedCorners(
                for: block.value,
                hasLeftConnector: index > 0,
                hasRightConnector: index + 1 < blocks.count
            )
            UIBezierPath(
                roundedRect: blockRect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
            ).fill()
        }
        context.restoreGState()
    }

    private func roundedCorners(
        for value: Int,
        hasLeftConnector: Bool,
        hasRightConnector: Bool
    ) -> UIRectCorner {
        if value == 1 {
            return [.topLeft, .topRight]
        }

        var corners: UIRectCorner = [.bottomLeft, .bottomRight]
        if !hasLeftConnector { corners.insert(.topLeft) }
        if !hasRightConnector { corners.insert(.topRight) }
        return corners
    }

    private func drawTransitionGradient(
        context: CGContext,
        x: CGFloat,
        activeY: CGFloat,
        inactiveY: CGFloat,
        blockHeight: CGFloat,
        width: CGFloat
    ) {
        let colors = [activeColor.cgColor, inactiveColor.cgColor] as CFArray
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0, 1]
        ) else { return }

        let gradientTop = min(activeY, inactiveY) + blockHeight * 0.5
        let gradientBottom = max(activeY, inactiveY) - blockHeight * 0.5
        guard gradientBottom > gradientTop else { return }
        let connectorX = x - width * 0.5
        let connectorRect = CGRect(
            x: connectorX,
            y: gradientTop,
            width: width,
            height: gradientBottom - gradientTop
        )
        context.saveGState()
        context.clip(to: connectorRect)
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: connectorRect.midX, y: gradientTop),
            end: CGPoint(x: connectorRect.midX, y: gradientBottom),
            options: []
        )
        context.restoreGState()
    }

    private func drawAxis(day: Range<TimeInterval>, plotRect: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: axisTextColor
        ]
        let labelY = bounds.height - 34
        for hour in [0, 8, 12, 16, 24] {
            let text = String(format: "%02d:00", hour)
            let size = text.size(withAttributes: attributes)
            let timestamp = day.lowerBound + TimeInterval(hour * 3600)
            let x = xPosition(timestamp, day: day, plotRect: plotRect)
            let originX = min(bounds.width - size.width, max(0, x - size.width * 0.5))
            text.draw(at: CGPoint(x: originX, y: labelY), withAttributes: attributes)
        }
    }

    private func drawSelection(
        context: CGContext,
        day: Range<TimeInterval>,
        activeY: CGFloat,
        plotRect: CGRect
    ) {
        let ranges = activeRanges
        guard let selectedRangeIndex, ranges.indices.contains(selectedRangeIndex) else { return }
        let range = ranges[selectedRangeIndex]
        let centerX = xPosition((range.lowerBound + range.upperBound) * 0.5, day: day, plotRect: plotRect)

        let duration = max(0, Int(range.upperBound - range.lowerBound))
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        let durationText = hours > 0 ? "Duration: \(hours)h \(minutes)min" : "Duration: \(minutes)min"
        let timeText = "\(timeString(range.lowerBound)) - \(timeString(range.upperBound))"

        let font = UIFont.systemFont(ofSize: 15)
        let lineHeight = font.lineHeight
        let textWidth = max(
            durationText.size(withAttributes: [.font: font]).width,
            timeText.size(withAttributes: [.font: font]).width
        )
        let tooltipSize = CGSize(width: textWidth + 24, height: lineHeight * 2 + 18)
        let tooltipX = min(bounds.width - tooltipSize.width - 8, max(8, centerX - tooltipSize.width * 0.5))
        let tooltipRect = CGRect(origin: CGPoint(x: tooltipX, y: 8), size: tooltipSize)

        context.saveGState()
        context.setStrokeColor(UIColor(white: 0.72, alpha: 1).cgColor)
        context.setLineWidth(1)
        context.setLineDash(phase: 0, lengths: [2, 3])
        context.move(to: CGPoint(x: centerX, y: tooltipRect.maxY))
        context.addLine(to: CGPoint(x: centerX, y: activeY - 10))
        context.strokePath()
        context.restoreGState()

        UIColor(white: 0.04, alpha: 1).setFill()
        UIBezierPath(roundedRect: tooltipRect, cornerRadius: 9).fill()
        let textAttributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.white]
        drawCentered(durationText, y: tooltipRect.minY + 8, rect: tooltipRect, attributes: textAttributes)
        drawCentered(timeText, y: tooltipRect.minY + 8 + lineHeight, rect: tooltipRect, attributes: textAttributes)
    }

    private func drawCentered(
        _ text: String,
        y: CGFloat,
        rect: CGRect,
        attributes: [NSAttributedString.Key: Any]
    ) {
        let size = text.size(withAttributes: attributes)
        text.draw(at: CGPoint(x: rect.midX - size.width * 0.5, y: y), withAttributes: attributes)
    }

    @objc private func didTap(_ gesture: UITapGestureRecognizer) {
        guard let day = dayRange else { return }
        let horizontalInset: CGFloat = 12
        let plotRect = CGRect(x: horizontalInset, y: 74, width: bounds.width - horizontalInset * 2, height: max(70, bounds.height - 142))
        let location = gesture.location(in: self)
        let timestamp = day.lowerBound
            + TimeInterval((location.x - plotRect.minX) / plotRect.width) * (day.upperBound - day.lowerBound)
        guard let index = activeRanges.firstIndex(where: { $0.contains(timestamp) }) else { return }
        selectedRangeIndex = index
        setNeedsDisplay()
    }

    private var dayRange: Range<TimeInterval>? {
        guard let timestamp = points.first?.timestamp else { return nil }
        let start = calendar.startOfDay(for: Date(timeIntervalSince1970: timestamp)).timeIntervalSince1970
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: Date(timeIntervalSince1970: start)) else { return nil }
        return start..<endDate.timeIntervalSince1970
    }

    private var activeRanges: [Range<TimeInterval>] {
        guard let day = dayRange else { return [] }
        let samples = normalizedSamples(in: day)
        var ranges: [Range<TimeInterval>] = []
        for index in samples.indices where samples[index].value == 1 {
            let end = index + 1 < samples.count ? samples[index + 1].timestamp : day.upperBound
            guard end > samples[index].timestamp else { continue }
            if let last = ranges.last, last.upperBound == samples[index].timestamp {
                ranges[ranges.count - 1] = last.lowerBound..<end
            } else {
                ranges.append(samples[index].timestamp..<end)
            }
        }
        return ranges
    }

    private func normalizedSamples(in day: Range<TimeInterval>) -> [BinaryTimelinePoint] {
        let values = points.filter { day.contains($0.timestamp) }
        guard !values.isEmpty else { return [] }
        var result = values
        if values[0].timestamp > day.lowerBound {
            result.insert(BinaryTimelinePoint(timestamp: day.lowerBound, value: 0), at: 0)
        }
        return result
    }

    private func stateBlocks(in day: Range<TimeInterval>) -> [StateBlock] {
        let samples = normalizedSamples(in: day)
        guard let first = samples.first else { return [] }

        var blocks: [StateBlock] = []
        var start = first.timestamp
        var value = first.value
        for sample in samples.dropFirst() where sample.value != value {
            blocks.append(StateBlock(start: start, end: sample.timestamp, value: value))
            start = sample.timestamp
            value = sample.value
        }
        blocks.append(StateBlock(start: start, end: day.upperBound, value: value))
        return blocks.filter { $0.end > $0.start }
    }

    private func xPosition(_ timestamp: TimeInterval, day: Range<TimeInterval>, plotRect: CGRect) -> CGFloat {
        let progress = (timestamp - day.lowerBound) / (day.upperBound - day.lowerBound)
        return plotRect.minX + CGFloat(min(1, max(0, progress))) * plotRect.width
    }

    private func timeString(_ timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }
}
