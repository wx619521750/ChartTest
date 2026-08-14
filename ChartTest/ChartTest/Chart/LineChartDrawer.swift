//
//  LineChartDrawer.swift
//  ChartTest
//
//  Created by Carlo on 1/14/26.
//

import UIKit

class LineChartDrawer {
    //文本框的大小
    //    var circleLabelSize = CGSize.init(width: 80, height: 40)
    //图表模型
    var chartModel = ChartModel()
    var layer = CALayer()
    private unowned let chartView: LineChartView

    init(chartView: LineChartView) {
        self.chartView = chartView
    }
    //需要绘制的数据
    
    func draw(layer:CALayer,ctx:CGContext,chartModel:ChartModel){
        self.chartModel = chartModel
        self.layer = layer
        drawAxis(layer: layer, ctx: ctx, chartModel: chartModel, data: chartModel.lineModel.pointsShouldDraw)
        drawLine(layer: layer, ctx: ctx, chartModel: chartModel, data: chartModel.lineModel.pointsShouldDraw)
        if case .distance = chartModel.gapStyle {
            drawEmptyArea(layer: layer, ctx: ctx, chartModel: chartModel, data: chartModel.lineModel.pointsShouldDraw)
        }
        drawAxisLable(layer: layer, ctx: ctx, chartModel: chartModel, data: chartModel.lineModel.pointsShouldDraw)
        drawAxisMaxMinLable(layer: layer, ctx: ctx, chartModel: chartModel, data: chartModel.lineModel.pointsShouldDraw)
        drawAxisDataMaxMinLable(layer: layer, ctx: ctx, chartModel: chartModel, data: chartModel.lineModel.pointsShouldDraw)
        drawHVLine(layer: layer, ctx: ctx, chartModel: chartModel, data: chartModel.lineModel.pointsShouldDraw)
        drawItemCircle(layer: layer, ctx: ctx, chartModel: chartModel, data: chartModel.lineModel.pointsShouldDraw)
    }
    
    
    
    //绘制坐标轴
    func drawAxis(layer:CALayer,ctx:CGContext,chartModel:ChartModel,data:[ChartPointModel]){
        ctx.saveGState()
        switch chartModel.topAxisLineStyle {
        case .line(let width, let color):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width)
            if chartModel.horizontalAxisFullFrame{
                ctx.move(to: CGPoint(x: 0, y: chartModel.chartContentInsert.top))
                ctx.addLine(to: CGPoint(x: layer.bounds.width, y: chartModel.chartContentInsert.top))
                
            }else{
                ctx.move(to: CGPoint(x: chartModel.chartContentInsert.left, y: chartModel.chartContentInsert.top))
                ctx.addLine(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: chartModel.chartContentInsert.top))
            }
            ctx.strokePath()
        case .dashLine(let width, let color, let lengths):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width)
            ctx.setLineDash(phase: 0, lengths: lengths)
            if chartModel.horizontalAxisFullFrame{
                ctx.move(to: CGPoint(x: 0, y: chartModel.chartContentInsert.top))
                ctx.addLine(to: CGPoint(x: layer.bounds.width, y: chartModel.chartContentInsert.top))
                
            }else{
                ctx.move(to: CGPoint(x: chartModel.chartContentInsert.left, y: chartModel.chartContentInsert.top))
                ctx.addLine(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: chartModel.chartContentInsert.top))
            }
            ctx.strokePath()
        case .none:
            break
        }
        ctx.restoreGState()
        ctx.saveGState()
        switch chartModel.bottomAxisLineStyle {
        case .line(let width, let color):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width)
            if chartModel.horizontalAxisFullFrame{
                ctx.move(to: CGPoint(x: 0, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
                ctx.addLine(to: CGPoint(x: layer.bounds.width, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
            }else{
                ctx.move(to: CGPoint(x: chartModel.chartContentInsert.left, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
                ctx.addLine(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
            }
            ctx.strokePath()
        case .dashLine(let width, let color, let lengths):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width)
            ctx.setLineDash(phase: 0, lengths: lengths)
            if chartModel.horizontalAxisFullFrame{
                ctx.move(to: CGPoint(x: 0, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
                ctx.addLine(to: CGPoint(x: layer.bounds.width, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
            }else{
                ctx.move(to: CGPoint(x: chartModel.chartContentInsert.left, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
                ctx.addLine(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
            }
            ctx.strokePath()
        case .none:
            break
        }
        ctx.restoreGState()
        ctx.saveGState()
        switch chartModel.leftAxisLineStyle {
        case .line(let width, let color):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width)
            if chartModel.verticalAxisFullFrame{
                ctx.move(to: CGPoint(x: chartModel.chartContentInsert.left, y: 0))
                ctx.addLine(to: CGPoint(x: chartModel.chartContentInsert.left, y: layer.bounds.height))
            }else{
                ctx.move(to: CGPoint(x: chartModel.chartContentInsert.left, y: chartModel.chartContentInsert.top))
                ctx.addLine(to: CGPoint(x: chartModel.chartContentInsert.left, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
            }
            ctx.strokePath()
        case .dashLine(let width, let color, let lengths):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width)
            ctx.setLineDash(phase: 0, lengths: lengths)
            if chartModel.verticalAxisFullFrame{
                ctx.move(to: CGPoint(x: chartModel.chartContentInsert.left, y: 0))
                ctx.addLine(to: CGPoint(x: chartModel.chartContentInsert.left, y: layer.bounds.height))
            }else{
                ctx.move(to: CGPoint(x: chartModel.chartContentInsert.left, y: chartModel.chartContentInsert.top))
                ctx.addLine(to: CGPoint(x: chartModel.chartContentInsert.left, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
            }
            ctx.strokePath()
        case .none:
            break
        }
        ctx.restoreGState()
        ctx.saveGState()
        switch chartModel.rightAxisLineStyle {
        case .line(let width, let color):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width)
            if chartModel.verticalAxisFullFrame{
                ctx.move(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: 0))
                ctx.addLine(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: layer.bounds.height))
            }else{
                ctx.move(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: chartModel.chartContentInsert.top))
                ctx.addLine(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
            }
            ctx.strokePath()
        case .dashLine(let width, let color, let lengths):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width)
            ctx.setLineDash(phase: 0, lengths: lengths)
            if chartModel.verticalAxisFullFrame{
                ctx.move(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: 0))
                ctx.addLine(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: layer.bounds.height))
            }else{
                ctx.move(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: chartModel.chartContentInsert.top))
                ctx.addLine(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
            }
            ctx.strokePath()
        case .none:
            break
        }
        ctx.restoreGState()
        
    }
    //绘制数据曲线
    func drawLine(layer:CALayer,ctx:CGContext,chartModel:ChartModel,data:[ChartPointModel]){
        guard data.count>0 else{
            return
        }
        ctx.saveGState()
        let lineWidth:CGFloat = getLineWidth()

        let clipRect = CGRect(
            x: chartModel.chartContentInsert.left,
            y: chartModel.chartContentInsert.top-lineWidth*0.5,
            width: layer.bounds.width - chartModel.chartContentInsert.left - chartModel.chartContentInsert.right,
            height: layer.bounds.height - chartModel.chartContentInsert.top - chartModel.chartContentInsert.bottom+lineWidth
        )
        ctx.clip(to: clipRect)
        
        if case .distance = chartModel.gapStyle {
            ctx.addRect(clipRect)
            for point in chartModel.lineModel.emptyAreas{
                let point1 = ptPointFromPoint(point: .init(x: point.left, y: 0))
                let point2 = ptPointFromPoint(point: .init(x: point.right, y: 0))
                let gapRect:CGRect = .init(x: point1.x, y:chartModel.chartContentInsert.top-lineWidth*0.5, width: point2.x-point1.x, height: layer.bounds.height-chartModel.chartContentInsert.top-chartModel.chartContentInsert.bottom+lineWidth)
                ctx.addRect(gapRect)
            }
            ctx.clip(using: .evenOdd)
        }

        let paths = makeLineAndAreaPaths(
            layer: layer,
            chartModel: chartModel,
            data: data
        )

        if let areaPath = paths.areaPath,
           let verticalBGColorRnages = chartModel.verticalBGColorRnages,
           !verticalBGColorRnages.isEmpty {
            drawLineBottomGradient(
                ctx: ctx,
                areaPath: areaPath,
                colorRanges: verticalBGColorRnages
            )
        }

        switch chartModel.lineModel.datalineStyle {
        case .straight(let width, let color):
            ctx.setLineWidth(width)
            ctx.setStrokeColor(color.cgColor)
            ctx.addPath(paths.linePath)
        case .bezier(let width, let color),
             .monotoneCubic(let width, let color),
             .catmullRom(let width, let color):
            ctx.setLineWidth(width)
            // 曲线路径使用圆角连接和圆形端点，避免端点出现尖锐接缝。
            ctx.setLineJoin(.round)
            ctx.setLineCap(.round)
            ctx.setStrokeColor(color.cgColor)
            ctx.addPath(paths.linePath)
        }
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        
        
        
        for (index,verticalColorRnage) in chartModel.verticalColorRnages.enumerated() {
            let toppt = ptPointFromPoint(point: .init(x: 0, y: verticalColorRnage.top ))
            let bottompt = ptPointFromPoint(point: .init(x: 0, y: verticalColorRnage.bottom ))
            
            let topY = toppt.y
            let bottomY = bottompt.y
            let colors = [
                verticalColorRnage.topColor.cgColor,
                verticalColorRnage.bottomColor.cgColor
            ]
            
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            )!
            
            ctx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: index == 0 ?topY-lineWidth*0.5:topY),
                end: CGPoint(x: 0, y: index == chartModel.verticalColorRnages.count-1 ?bottomY+lineWidth:bottomY),
                options: []
            )
        }
        
        ctx.restoreGState()
        
    }

    //一次遍历生成曲线路径和曲线下方面积路径，避免背景和线条重复计算贝塞尔曲线
    private func makeLineAndAreaPaths(
        layer: CALayer,
        chartModel: ChartModel,
        data: [ChartPointModel]
    ) -> (linePath: CGPath, areaPath: CGPath?) {
        let segments: [[ChartPointModel]]
        switch chartModel.gapStyle {
        case .none:
            segments = [data]
        case .distance:
            segments = continuousDataSegments(data)
        }
        let linePath = CGMutablePath()
        let areaPath = CGMutablePath()
        let bottomY = layer.bounds.height - chartModel.chartContentInsert.bottom
        var hasAreaPath = false

        for segment in segments {
            let points = segment.map {
                ptPointFromPoint(point: .init(x: $0.x, y: $0.y))
            }
            guard let firstPoint = points.first else { continue }
            linePath.move(to: firstPoint)

            if points.count > 1 {
                hasAreaPath = true
                areaPath.move(to: CGPoint(x: firstPoint.x, y: bottomY))
                areaPath.addLine(to: firstPoint)
            }

            switch chartModel.lineModel.datalineStyle {
            case .straight:
                for pt in points.dropFirst() {
                    linePath.addLine(to: pt)
                    areaPath.addLine(to: pt)
                }
            case .bezier:
                for index in 1..<points.count {
                    let prePt = points[index - 1]
                    let pt = points[index]
                    if shouldFallbackToStraightLine(from: prePt, to: pt) {
                        // 点在屏幕上非常密集时，贝塞尔视觉差异很小，退化为直线可明显减少路径计算。
                        linePath.addLine(to: pt)
                        areaPath.addLine(to: pt)
                    } else {
                        let t = 0.5
                        let control1 = CGPoint(x: prePt.x + (pt.x - prePt.x) * t, y: prePt.y)
                        let control2 = CGPoint(x: pt.x - (pt.x - prePt.x) * t, y: pt.y)
                        linePath.addCurve(to: pt, control1: control1, control2: control2)
                        areaPath.addCurve(to: pt, control1: control1, control2: control2)
                    }
                }
            case .monotoneCubic:
                let controls = monotoneCubicControlPoints(points)
                for index in controls.indices {
                    let startPoint = points[index]
                    let endPoint = points[index + 1]
                    if shouldFallbackToStraightLine(from: startPoint, to: endPoint) {
                        linePath.addLine(to: endPoint)
                        areaPath.addLine(to: endPoint)
                    } else {
                        linePath.addCurve(
                            to: endPoint,
                            control1: controls[index].control1,
                            control2: controls[index].control2
                        )
                        areaPath.addCurve(
                            to: endPoint,
                            control1: controls[index].control1,
                            control2: controls[index].control2
                        )
                    }
                }
            case .catmullRom:
                let controls = catmullRomControlPoints(points)
                for index in controls.indices {
                    let startPoint = points[index]
                    let endPoint = points[index + 1]
                    if shouldFallbackToStraightLine(from: startPoint, to: endPoint) {
                        linePath.addLine(to: endPoint)
                        areaPath.addLine(to: endPoint)
                    } else {
                        linePath.addCurve(
                            to: endPoint,
                            control1: controls[index].control1,
                            control2: controls[index].control2
                        )
                        areaPath.addCurve(
                            to: endPoint,
                            control1: controls[index].control1,
                            control2: controls[index].control2
                        )
                    }
                }
            }

            if let lastPoint = points.last, points.count > 1 {
                areaPath.addLine(to: CGPoint(x: lastPoint.x, y: bottomY))
                areaPath.closeSubpath()
            }
        }

        return (linePath, hasAreaPath ? areaPath : nil)
    }

    /// 当相邻点的屏幕 X 距离小于配置阈值时，将当前曲线段退化为直线。
    private func shouldFallbackToStraightLine(from start: CGPoint, to end: CGPoint) -> Bool {
        let minimumDistance = chartModel.bezierToLineMinDistance
        return minimumDistance > 0 && abs(end.x - start.x) < minimumDistance
    }

    /// 计算单调三次 Hermite 曲线对应的贝塞尔控制点，避免曲线越过相邻数据点的值域。
    private func monotoneCubicControlPoints(
        _ points: [CGPoint]
    ) -> [(control1: CGPoint, control2: CGPoint)] {
        guard points.count > 1 else { return [] }

        let minimumDistance: CGFloat = 0.0001
        var intervals = [CGFloat](repeating: 0, count: points.count - 1)
        var slopes = [CGFloat](repeating: 0, count: points.count - 1)

        for index in intervals.indices {
            let distanceX = points[index + 1].x - points[index].x
            intervals[index] = distanceX
            if distanceX > minimumDistance {
                slopes[index] = (points[index + 1].y - points[index].y) / distanceX
            }
        }

        var tangents = [CGFloat](repeating: 0, count: points.count)
        tangents[0] = slopes[0]
        tangents[points.count - 1] = slopes[slopes.count - 1]

        if points.count > 2 {
            for index in 1..<(points.count - 1) {
                let previousSlope = slopes[index - 1]
                let nextSlope = slopes[index]
                guard previousSlope * nextSlope > 0 else {
                    tangents[index] = 0
                    continue
                }

                let previousInterval = max(intervals[index - 1], minimumDistance)
                let nextInterval = max(intervals[index], minimumDistance)
                let firstWeight = 2 * nextInterval + previousInterval
                let secondWeight = nextInterval + 2 * previousInterval
                tangents[index] = (firstWeight + secondWeight)
                    / (firstWeight / previousSlope + secondWeight / nextSlope)
            }
        }

        return intervals.indices.map { index in
            let distanceX = intervals[index]
            let controlDistance = distanceX / 3
            return (
                control1: CGPoint(
                    x: points[index].x + controlDistance,
                    y: points[index].y + tangents[index] * controlDistance
                ),
                control2: CGPoint(
                    x: points[index + 1].x - controlDistance,
                    y: points[index + 1].y - tangents[index + 1] * controlDistance
                )
            )
        }
    }

    /// 将 centripetal Catmull-Rom 曲线转换为 Core Graphics 可绘制的三次贝塞尔控制点。
    private func catmullRomControlPoints(
        _ points: [CGPoint]
    ) -> [(control1: CGPoint, control2: CGPoint)] {
        guard points.count > 1 else { return [] }

        var controls: [(control1: CGPoint, control2: CGPoint)] = []
        controls.reserveCapacity(points.count - 1)

        for index in 0..<(points.count - 1) {
            let point1 = points[index]
            let point2 = points[index + 1]
            let point0 = index > 0
                ? points[index - 1]
                : CGPoint(x: point1.x * 2 - point2.x, y: point1.y * 2 - point2.y)
            let point3 = index + 2 < points.count
                ? points[index + 2]
                : CGPoint(x: point2.x * 2 - point1.x, y: point2.y * 2 - point1.y)

            let time0: CGFloat = 0
            let time1 = time0 + catmullRomParameterDistance(from: point0, to: point1)
            let time2 = time1 + catmullRomParameterDistance(from: point1, to: point2)
            let time3 = time2 + catmullRomParameterDistance(from: point2, to: point3)
            let segmentDuration = time2 - time1

            let firstTangent = catmullRomTangent(
                previous: point0,
                current: point1,
                next: point2,
                previousTime: time0,
                currentTime: time1,
                nextTime: time2
            )
            let secondTangent = catmullRomTangent(
                previous: point1,
                current: point2,
                next: point3,
                previousTime: time1,
                currentTime: time2,
                nextTime: time3
            )
            let tangent1 = CGPoint(
                x: firstTangent.x * segmentDuration,
                y: firstTangent.y * segmentDuration
            )
            let tangent2 = CGPoint(
                x: secondTangent.x * segmentDuration,
                y: secondTangent.y * segmentDuration
            )

            let minimumX = min(point1.x, point2.x)
            let maximumX = max(point1.x, point2.x)
            let control1 = CGPoint(
                x: min(maximumX, max(minimumX, point1.x + tangent1.x / 3)),
                y: point1.y + tangent1.y / 3
            )
            let control2 = CGPoint(
                x: min(maximumX, max(minimumX, point2.x - tangent2.x / 3)),
                y: point2.y - tangent2.y / 3
            )
            controls.append((control1: control1, control2: control2))
        }

        return controls
    }

    /// 计算非均匀 Catmull-Rom 参数区间内某个数据点的切线。
    private func catmullRomTangent(
        previous: CGPoint,
        current: CGPoint,
        next: CGPoint,
        previousTime: CGFloat,
        currentTime: CGFloat,
        nextTime: CGFloat
    ) -> CGPoint {
        let previousDuration = currentTime - previousTime
        let nextDuration = nextTime - currentTime
        let totalDuration = nextTime - previousTime

        let previousX = (current.x - previous.x) / previousDuration
        let previousY = (current.y - previous.y) / previousDuration
        let totalX = (next.x - previous.x) / totalDuration
        let totalY = (next.y - previous.y) / totalDuration
        let nextX = (next.x - current.x) / nextDuration
        let nextY = (next.y - current.y) / nextDuration

        return CGPoint(
            x: previousX - totalX + nextX,
            y: previousY - totalY + nextY
        )
    }

    /// alpha=0.5 的参数距离可减少 Catmull-Rom 在密集点附近产生尖点和回环。
    private func catmullRomParameterDistance(from start: CGPoint, to end: CGPoint) -> CGFloat {
        let distance = hypot(end.x - start.x, end.y - start.y)
        return max(sqrt(distance), 0.0001)
    }

    //绘制曲线下方的渐变背景
    private func drawLineBottomGradient(
        ctx: CGContext,
        areaPath: CGPath,
        colorRanges: [VerticalColorRange]
    ) {
        ctx.saveGState()
        ctx.addPath(areaPath)
        ctx.clip()

        for verticalBGColorRnage in colorRanges {
            let topPt = ptPointFromPoint(point: .init(x: 0, y: verticalBGColorRnage.top))
            let bottomPt = ptPointFromPoint(point: .init(x: 0, y: verticalBGColorRnage.bottom))
            let colors = [
                verticalBGColorRnage.topColor.cgColor,
                verticalBGColorRnage.bottomColor.cgColor
            ]

            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            ) else { continue }

            ctx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: topPt.y),
                end: CGPoint(x: 0, y: bottomPt.y),
                options: []
            )
        }

        ctx.restoreGState()
    }

    //按照 gap 将数据拆分成多段连续数据，避免背景跨过空洞区域
    private func continuousDataSegments(_ data: [ChartPointModel]) -> [[ChartPointModel]] {
        var segments: [[ChartPointModel]] = []
        var current: [ChartPointModel] = []

        for item in data {
            if item.dataType == .gap {
                if !current.isEmpty {
                    segments.append(current)
                    current.removeAll()
                }
            } else {
                current.append(item)
            }
        }

        if !current.isEmpty {
            segments.append(current)
        }

        return segments
    }
    
    func getLineWidth()->CGFloat{
        var lineWidth:CGFloat = 1
        switch chartModel.lineModel.datalineStyle{
        case .straight(let width, _):
          lineWidth = width
        case .bezier(let width, _),
             .monotoneCubic(let width, _),
             .catmullRom(let width, _):
            lineWidth = width
        }
        return lineWidth
    }
    
    //绘制空数据区域
    func drawEmptyArea(layer:CALayer,ctx:CGContext,chartModel:ChartModel,data:[ChartPointModel]){
        ctx.saveGState()

        let clipRect = CGRect(
            x: chartModel.chartContentInsert.left,
            y: chartModel.chartContentInsert.top,
            width: layer.bounds.width - chartModel.chartContentInsert.left - chartModel.chartContentInsert.right,
            height: layer.bounds.height - chartModel.chartContentInsert.top - chartModel.chartContentInsert.bottom
        )
        
        ctx.clip(to: clipRect)
        for point in chartModel.lineModel.emptyAreas{
            var point1 = ptPointFromPoint(point: .init(x: point.left, y: 0))
            if point1.x<chartModel.chartContentInsert.left{
                point1.x = chartModel.chartContentInsert.left
            }
            var point2 = ptPointFromPoint(point: .init(x: point.right, y: 0))
            if point2.x>layer.bounds.width-chartModel.chartContentInsert.right{
                point2.x = layer.bounds.width-chartModel.chartContentInsert.right
            }
            let gapRect:CGRect = .init(x: point1.x, y:chartModel.chartContentInsert.top, width: point2.x-point1.x, height: layer.bounds.height-chartModel.chartContentInsert.top-chartModel.chartContentInsert.bottom)
            
            drawDiagonalLines(in: ctx, rect: gapRect, spacing: 10)
            UIGraphicsPushContext(ctx)
            if gapRect.width>10{
                drawText(NSAttributedString.init(string: "G\nA\nP",attributes: [.foregroundColor:UIColor(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1.0),.font:UIFont.systemFont(ofSize: 13)]), point: .init(x: gapRect.minX+gapRect.width*0.5, y: gapRect.minY+gapRect.height*0.5), anchor: .center)
            }
            UIGraphicsPopContext()
        }
        
        ctx.restoreGState()
        
    }
    
    /// 绘制斜线
    /// - Parameters:
    ///   - ctx: 图形上下文
    ///   - rect: 绘制区域
    ///   - angle: 倾斜角度（度）
    ///   - spacing: 线间距
    private func drawDiagonalLines(in ctx: CGContext, rect: CGRect, spacing: CGFloat) {
        ctx.setLineWidth(1)
        ctx.setStrokeColor(UIColor(red: 234/255.0, green: 234/255.0, blue: 234/255.0, alpha: 1.0).cgColor)
        var y = rect.minY-rect.width
        while y>=rect.minY-rect.width&&y<=rect.maxY {
            ctx.move(to: .init(x: rect.origin.x, y: y))
            ctx.addLine(to: .init(x: rect.origin.x+rect.width, y: y+rect.width))
            ctx.strokePath()
            y+=spacing
        }
        
    }
    
    
    //绘制水平垂直的线条
    func drawHVLine(layer:CALayer,ctx:CGContext,chartModel:ChartModel,data:[ChartPointModel]){
        for horizontalLine in chartModel.horizontalLines {
            ctx.saveGState()
//            let clipRect = CGRect(
//                x: chartModel.chartContentInsert.left,
//                y: chartModel.chartContentInsert.top,
//                width: layer.bounds.width - chartModel.chartContentInsert.left - chartModel.chartContentInsert.right,
//                height: layer.bounds.height - chartModel.chartContentInsert.top - chartModel.chartContentInsert.bottom
//            )
//
//            ctx.clip(to: clipRect)
            var point = ptPointFromPoint(point: .init(x: 0, y: horizontalLine.y))
            switch horizontalLine.lineStyle {
            case .line(let width, let color):
                ctx.setLineWidth(width)
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineDash(phase: 0, lengths: [])
            case .dashLine(let width, let color, let lengths):
                ctx.setLineWidth(width)
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineDash(phase: 0, lengths: lengths)
            case .none:
                ctx.restoreGState()
                continue
            }
            let startPoint = CGPoint.init(x: chartModel.chartContentInsert.left, y: point.y)
            let endPoint = CGPoint.init(x: layer.bounds.width-chartModel.chartContentInsert.right, y: point.y)
            ctx.move(to: startPoint)
            ctx.addLine(to: endPoint)
            ctx.strokePath()
            ctx.restoreGState()
            let padding = UIEdgeInsets.init(top: 4, left: 6, bottom: 4, right: 6)
            switch horizontalLine.lableStyle {
                
            case .left(let color, let font, let offset):
                point.x = chartModel.chartContentInsert.left+(offset ?? 0)
                if point.y<chartModel.chartContentInsert.top||point.y>layer.bounds.height-chartModel.chartContentInsert.bottom{
                    continue
                }
                let str = horizontalLineAttributedText(horizontalLine, color: color, font: font)
                let positions = horizontalLinesMaxMinDrawY(insert: padding, distance: 4)
                let y = horizontalLine.y == chartModel.horizontalLines.map(\.y).min() ? positions.0 : positions.1
                UIGraphicsPushContext(ctx)
                drawText(str, point: CGPoint(x: point.x, y: y), anchor: .maxxcentery, backgroundColor: color.withAlphaComponent(0.1), padding: padding)
                UIGraphicsPopContext()
            case .right(let color, let font, let offset):
                point.x = layer.bounds.width-chartModel.chartContentInsert.right+(offset ?? 0)
                let point = ptPointFromPoint(point: .init(x: 0, y: horizontalLine.y))
                if point.y<chartModel.chartContentInsert.top||point.y>layer.bounds.height-chartModel.chartContentInsert.bottom{
                    continue
                }
                let str = horizontalLineAttributedText(horizontalLine, color: color, font: font)
                let positions = horizontalLinesMaxMinDrawY(insert: padding, distance: 4)
                let y = horizontalLine.y == chartModel.horizontalLines.map(\.y).min() ? positions.0 : positions.1
                UIGraphicsPushContext(ctx)
                drawText(str, point: CGPoint(x: point.x, y: y), anchor: .minxcentery, backgroundColor: color.withAlphaComponent(0.1), padding: padding)
                UIGraphicsPopContext()
            default:break
            }
            
        }
        ctx.saveGState()
        let clipRect = CGRect(
            x: chartModel.chartContentInsert.left,
            y: chartModel.chartContentInsert.top,
            width: layer.bounds.width - chartModel.chartContentInsert.left - chartModel.chartContentInsert.right,
            height: layer.bounds.height - chartModel.chartContentInsert.top - chartModel.chartContentInsert.bottom
        )
        
        ctx.clip(to: clipRect)
        for verticalLine in chartModel.verticalLines {
            let point = ptPointFromPoint(point: .init(x: verticalLine.x, y: 0))
            
            switch verticalLine.lineStyle {
            case .line(let width, let color):
                ctx.setLineWidth(width)
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineDash(phase: 0, lengths: [])
            case .dashLine(let width, let color, let lengths):
                ctx.setLineWidth(width)
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineDash(phase: 0, lengths: lengths)
            case .none:
                continue
            }
            let startPoint = CGPoint.init(x: point.x, y: chartModel.chartContentInsert.top)
            let endPoint = CGPoint.init(x: point.x, y: layer.bounds.height-chartModel.chartContentInsert.bottom)
            ctx.move(to: startPoint)
            ctx.addLine(to: endPoint)
            ctx.strokePath()
        }
        ctx.restoreGState()
    }
    
    //绘制圆点和数据详情
    func drawItemCircle(layer:CALayer,ctx:CGContext,chartModel:ChartModel,data:[ChartPointModel]){
        
        
        guard  let item = data.first(where: {$0.style != .normal}) else{return}
        guard case let .circle(radius ,width ,color) =  item.style else{return}
        let point = ptPointFromPoint(point: .init(x: item.x, y: item.y))
        if chartModel.chartContentInsert.left>point.x||point.x>layer.bounds.width-chartModel.chartContentInsert.right||chartModel.chartContentInsert.top>point.y||point.y>layer.bounds.height-chartModel.chartContentInsert.bottom{
            return
        }
        ctx.saveGState()
        
        if item.dataType == .data{
            if let firstRange = chartModel.verticalColorRnages.first(where: {$0.top>item.y&&$0.bottom<=item.y}){
                ctx.setLineWidth(width)
                ctx.setLineDash(phase: 0, lengths: [])
                ctx.setStrokeColor(UIColor.white.cgColor)
                ctx.addEllipse(in: CGRect(
                    x: point.x - radius,
                    y: point.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                ctx.strokePath()
                
                ctx.setLineWidth(radius-width)
                ctx.setFillColor(firstRange.topColor.cgColor)
                ctx.addEllipse(in: CGRect(
                    x: point.x - (radius-width*0.5),
                    y: point.y - (radius-width*0.5),
                    width: (radius-width*0.5) * 2,
                    height: (radius-width*0.5) * 2
                ))
                ctx.fillPath()
                ctx.setStrokeColor(firstRange.topColor.cgColor)
                ctx.setLineWidth(1)
                ctx.setLineDash(phase: 0, lengths: [6,3])
                ctx.move(to: .init(x: point.x, y: chartModel.chartContentInsert.top))
                ctx.addLine(to: .init(x: point.x, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
                ctx.strokePath()
            }else{
                ctx.setLineWidth(width)
                ctx.setLineDash(phase: 0, lengths: [])
                ctx.setStrokeColor(color.cgColor)
                ctx.addEllipse(in: CGRect(
                    x: point.x - radius,
                    y: point.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                ctx.strokePath()
                
                ctx.setLineWidth(radius-width)
                ctx.setFillColor(UIColor.white.cgColor)
                ctx.addEllipse(in: CGRect(
                    x: point.x - (radius-width*0.5),
                    y: point.y - (radius-width*0.5),
                    width: (radius-width*0.5) * 2,
                    height: (radius-width*0.5) * 2
                ))
                ctx.fillPath()
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineWidth(1)
                ctx.setLineDash(phase: 0, lengths: [6,3])
                ctx.move(to: .init(x: point.x, y: chartModel.chartContentInsert.top))
                ctx.addLine(to: .init(x: point.x, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
                ctx.strokePath()
            }
        }
        ctx.restoreGState()
        if item.dataType == .data{
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: item.detailFont,
                .foregroundColor: item.detailColor
            ]
            let defaultText = XYAttrModel(
                xAttr: NSAttributedString(
                    string: Date(timeIntervalSince1970: item.x).toString(format: "yyyy/MM/dd HH:mm"),
                    attributes: attributes
                ),
                yAttr: NSAttributedString(string: String(format: "%.1f", item.y), attributes: attributes)
            )
            let text = chartView.delegate?.lineChartViewTapedItemFormatStrs?(
                chartView: chartView,
                x: item.x,
                y: item.y,
                color: item.detailColor,
                font: item.detailFont
            ) ?? defaultText
            let attributedStrings = [text.yAttr, text.xAttr]
            item.detailSize = deteminItemDetaiFrameSize(strs: attributedStrings)
            let detailPoint = deteminItemDetailCenter(item: item)
            drawTooltip(ctx: ctx, center: detailPoint, size: item.detailSize)
            UIGraphicsPushContext(ctx)

            let contentHeight = text.yAttr.size().height + text.xAttr.size().height
            let contentTop = detailPoint.y - contentHeight * 0.5
            drawText(
                text.yAttr,
                point: CGPoint(x: detailPoint.x, y: contentTop + text.yAttr.size().height * 0.5),
                anchor: .center
            )
            drawText(
                text.xAttr,
                point: CGPoint(x: detailPoint.x, y: contentTop + text.yAttr.size().height + text.xAttr.size().height * 0.5),
                anchor: .center
            )
            UIGraphicsPopContext()
        }else{
            let leftStr = Date.init(timeIntervalSince1970: item.gapLeft).toString(format: "yyyy/MM/dd HH:mm")
            let rightStr = Date.init(timeIntervalSince1970: item.gapRight).toString(format: "yyyy/MM/dd HH:mm")
            
            let attributes: [NSAttributedString.Key: Any] = [.font:item.detailFont, .foregroundColor:item.detailColor]
            let strs = [
                NSAttributedString(string: "GAP", attributes: attributes),
                NSAttributedString(string: "\(leftStr) ~ \(rightStr)", attributes: attributes)
            ]
            item.detailSize = deteminItemDetaiFrameSize(strs: strs)
            let detailPoint = deteminItemDetailCenter(item: item)
            drawTooltip(ctx: ctx, center: detailPoint, size: item.detailSize)
            UIGraphicsPushContext(ctx)
            
            drawText(strs[0], point: .init(x: detailPoint.x, y: detailPoint.y-8), anchor: .center)
            drawText(strs[1], point: .init(x: detailPoint.x, y: detailPoint.y+8), anchor: .center)
            UIGraphicsPopContext()
        }
        
    }
    
    //通过数据点获取半透明文案区域中心位置
    func deteminItemDetailCenter(item:ChartPointModel)->CGPoint{
        let point = ptPointFromPoint(point: .init(x: item.x, y: item.y))
        let yOffset:CGFloat = 10
        var x = point.x
        var y = point.y+item.detailSize.height*0.5+yOffset
        if (x-item.detailSize.width*0.5)<chartModel.chartContentInsert.left{
            x = item.detailSize.width*0.5+chartModel.chartContentInsert.left
        }
        if (x+item.detailSize.width*0.5)>(layer.bounds.width-chartModel.chartContentInsert.right){
            x = layer.bounds.width-chartModel.chartContentInsert.right-item.detailSize.width*0.5
        }
        
        if y+item.detailSize.height*0.5>layer.bounds.height-chartModel.chartContentInsert.bottom{
            y = point.y-item.detailSize.height*0.5-yOffset
        }
        return .init(x: x, y: y)
    }
    
    func deteminItemDetaiFrameSize(strs:[NSAttributedString])->CGSize{
        var height:CGFloat = 0
        var width:CGFloat = 0
        for str in strs {
            let size = str.size()
            height += size.height
            width = max(size.width, width)
        }
        return .init(width: width+12, height: height+12)
    }
    
    //绘制轴线的刻度文本
    func drawAxisLable(layer:CALayer,ctx:CGContext,chartModel:ChartModel,data:[ChartPointModel]){
        ctx.saveGState()
        defer { ctx.restoreGState() }

        switch chartModel.bottomGraduationStepType {
        case .dateAdapt:
            let trup = getDateAdaptStamps()
            switch chartModel.bottomAxisLabelStyel {
            case .bottom(let color, let font,let offset):
                for item in trup.0{
                    let x = ptPointFromPoint(point: .init(x: item, y: 0)).x
                    let y = layer.bounds.height-chartModel.chartContentInsert.bottom+(offset ?? 0)
                    let date = Date.init(timeIntervalSince1970: item)
                    let str = chartView.delegate?.lineChartViewAxisGraduationFormatStr?(
                        chartView: chartView,
                        direction: .bottom,
                        value: item,
                        color: color,
                        font: font
                    ) ?? NSAttributedString(
                        string: date.toString(format: trup.1),
                        attributes: [.foregroundColor: color, .font: font]
                    )
                    UIGraphicsPushContext(ctx)
                    drawText(str, point: CGPoint.init(x: x, y: y), anchor: .centerxminy, clampToChartContent: false)
                    UIGraphicsPopContext()
                    switch chartModel.bottomGraduationType {
                    case .line(let lenght, let width, let color):
                        ctx.setStrokeColor(color.cgColor)
                        ctx.setLineWidth(width)
                        ctx.setLineDash(phase: 0, lengths: [])
                        let bottomY = layer.bounds.height-chartModel.chartContentInsert.bottom
                        let endY = lenght.map { bottomY-$0 } ?? chartModel.chartContentInsert.top
                        ctx.move(to: .init(x: x, y: bottomY))
                        ctx.addLine(to: .init(x: x, y: endY))
                    case .dashLine(let lenght, let width, let color, let lengths):
                        ctx.setStrokeColor(color.cgColor)
                        ctx.setLineWidth(width)
                        ctx.setLineDash(phase: 0, lengths: lengths)
                        let bottomY = layer.bounds.height-chartModel.chartContentInsert.bottom
                        let endY = lenght.map { bottomY-$0 } ?? chartModel.chartContentInsert.top
                        ctx.move(to: .init(x: x, y: bottomY))
                        ctx.addLine(to: .init(x: x, y: endY))
                    case .none:
                        break
                    }
                    
                }
                ctx.strokePath()
                
            default:
                break
            }

        case .distance, .seprateCount:
            let steps = generateAxisSteps(
                min: chartModel.minX,
                max: chartModel.maxX,
                type: chartModel.bottomGraduationStepType
            )
            switch chartModel.bottomAxisLabelStyel {
            case .bottom(let color, let font, let offset):
                for item in steps {
                    let x = ptPointFromPoint(point: .init(x: item, y: 0)).x
                    let bottomY = layer.bounds.height-chartModel.chartContentInsert.bottom
                    let textY = bottomY+(offset ?? 0)
                    let str = chartView.delegate?.lineChartViewAxisGraduationFormatStr?(
                        chartView: chartView,
                        direction: .bottom,
                        value: item,
                        color: color,
                        font: font
                    ) ?? NSAttributedString(
                        string: String(format: "%.1f", item),
                        attributes: [.foregroundColor: color, .font: font]
                    )
                    UIGraphicsPushContext(ctx)
                    drawText(
                        str,
                        point: CGPoint(x: x, y: textY),
                        anchor: .centerxminy,
                        clampToChartContent: false
                    )
                    UIGraphicsPopContext()

                    switch chartModel.bottomGraduationType {
                    case .line(let lenght, let width, let color):
                        ctx.setStrokeColor(color.cgColor)
                        ctx.setLineWidth(width)
                        ctx.setLineDash(phase: 0, lengths: [])
                        let endY = lenght.map { bottomY-$0 } ?? chartModel.chartContentInsert.top
                        ctx.move(to: CGPoint(x: x, y: bottomY))
                        ctx.addLine(to: CGPoint(x: x, y: endY))
                    case .dashLine(let lenght, let width, let color, let lengths):
                        ctx.setStrokeColor(color.cgColor)
                        ctx.setLineWidth(width)
                        ctx.setLineDash(phase: 0, lengths: lengths)
                        let endY = lenght.map { bottomY-$0 } ?? chartModel.chartContentInsert.top
                        ctx.move(to: CGPoint(x: x, y: bottomY))
                        ctx.addLine(to: CGPoint(x: x, y: endY))
                    case .none:
                        break
                    }
                }
                ctx.strokePath()
            default:
                break
            }

        case .none:
            break
        }
       
        
        
        let steps = generateAxisSteps(min: chartModel.minY, max: chartModel.maxY, type: chartModel.rightGraduationStepType)
        switch chartModel.rightAxisLabelStyel {
        case .right(let color, let font,let offset):
            for item in steps{
                let y = ptPointFromPoint(point: .init(x: 0, y: item)).y
                let x = layer.bounds.width-chartModel.chartContentInsert.right+(offset ?? 0)
                let str = chartView.delegate?.lineChartViewAxisGraduationFormatStr?(
                    chartView: chartView,
                    direction: .right,
                    value: item,
                    color: color,
                    font: font
                ) ?? NSAttributedString(string: String(format: "%.1f", item), attributes: [.foregroundColor:color,.font:font])
                UIGraphicsPushContext(ctx)
                let _ = drawText(str, point: CGPoint.init(x: x, y: y), anchor: .minxcentery, clampToChartContent: false)
                UIGraphicsPopContext()
                switch chartModel.rightGraduationType {
                case .line(let lenght, let width, let color):
                    ctx.setStrokeColor(color.cgColor)
                    ctx.setLineWidth(width)
                    ctx.setLineDash(phase: 0, lengths: [])
                    let rightX = layer.bounds.width-chartModel.chartContentInsert.right
                    let endX = lenght.map { rightX-$0 } ?? chartModel.chartContentInsert.left
                    ctx.move(to: .init(x: rightX, y:y))
                    ctx.addLine(to: .init(x: endX, y: y))
                case .dashLine(let lenght, let width, let color, let lengths):
                    ctx.setStrokeColor(color.cgColor)
                    ctx.setLineWidth(width)
                    ctx.setLineDash(phase: 0, lengths: lengths)
                    let rightX = layer.bounds.width-chartModel.chartContentInsert.right
                    let endX = lenght.map { rightX-$0 } ?? chartModel.chartContentInsert.left
                    ctx.move(to: .init(x: rightX, y:y))
                    ctx.addLine(to: .init(x: endX, y: y))
                case .none:
                    break
                }
            }
            ctx.strokePath()
        case .left(let color, let font, let offset):
            for item in steps {
                let y = ptPointFromPoint(point: .init(x: 0, y: item)).y
                let rightX = layer.bounds.width-chartModel.chartContentInsert.right
                let textRightX = rightX+(offset ?? 0)
                let str = chartView.delegate?.lineChartViewAxisGraduationFormatStr?(
                    chartView: chartView,
                    direction: .right,
                    value: item,
                    color: color,
                    font: font
                ) ?? NSAttributedString(string: String(format: "%.1f", item), attributes: [.foregroundColor:color,.font:font])
                let textLeftX = textRightX-str.size().width
                UIGraphicsPushContext(ctx)
                let _ = drawText(str, point: CGPoint(x: textRightX, y: y), anchor: .maxxcentery, clampToChartContent: false)
                UIGraphicsPopContext()

                // 右轴文字位于绘图区内时，刻度线在文字左侧结束，避免线条穿过文字。
                let lineEndX = textLeftX-4
                guard lineEndX > chartModel.chartContentInsert.left else { continue }
                switch chartModel.rightGraduationType {
                case .line(let lenght, let width, let color):
                    ctx.setStrokeColor(color.cgColor)
                    ctx.setLineWidth(width)
                    ctx.setLineDash(phase: 0, lengths: [])
                    let lineStartX = lenght.map { max(chartModel.chartContentInsert.left, lineEndX-$0) } ?? chartModel.chartContentInsert.left
                    ctx.move(to: .init(x: lineStartX, y: y))
                    ctx.addLine(to: .init(x: lineEndX, y: y))
                case .dashLine(let lenght, let width, let color, let lengths):
                    ctx.setStrokeColor(color.cgColor)
                    ctx.setLineWidth(width)
                    ctx.setLineDash(phase: 0, lengths: lengths)
                    let lineStartX = lenght.map { max(chartModel.chartContentInsert.left, lineEndX-$0) } ?? chartModel.chartContentInsert.left
                    ctx.move(to: .init(x: lineStartX, y: y))
                    ctx.addLine(to: .init(x: lineEndX, y: y))
                case .none:
                    break
                }
            }
            ctx.strokePath()
            
        default:
            break
        }
  
    }
    
    func generateAxisSteps(min: CGFloat, max: CGFloat, type: AxisStepType) -> [CGFloat] {
        guard min < max else {
            return []
        }
        
        switch type {
        case .distance(let distance, let align):
            guard distance > 0 else { return [] }
            
            if let alignValue = align {
                // 有 align：返回可以被 align 整除的数值
                // 首先找到 >= min 的第一个能被 align 整除的数
                let firstValue = ceil(min / alignValue) * alignValue
                // 然后生成所有符合 distance 间隔且能被 align 整除的数
                var result: [CGFloat] = []
                var current = firstValue
                while current <= max {
                    // 确保当前值在范围内且能被 align 整除
                    if current >= min && current <= max {
                        // 由于浮点数精度问题，使用容差判断整除
                        let remainder = current.truncatingRemainder(dividingBy: alignValue)
                        if abs(remainder) < 0.0001 || abs(remainder - alignValue) < 0.0001 {
                            result.append(current)
                        }
                    }
                    current += distance
                    // 防止浮点数无限循环
                    if current > max + distance {
                        break
                    }
                }
                return result
            } else {
                // 没有 align：包含最小值，步长为 distance
                var result: [CGFloat] = []
                var current = min
                while current <= max + 0.0001 { // 加容差避免浮点数精度问题
                    result.append(current)
                    current += distance
                    if result.count > 10000 { // 防止无限循环
                        break
                    }
                }
                return result
            }
            
        case .seprateCount(let count):
            guard count >= 2 else { return [min, max] }
            
            let step = (max - min) / CGFloat(count - 1)
            var result: [CGFloat] = []
            for i in 0..<count {
                let value = min + step * CGFloat(i)
                result.append(value)
            }
            return result
        default:return []
        }
    }
    
    func getDateAdaptStamps()->([TimeInterval],format:String){
        var stamps = [TimeInterval]()
        let range = chartModel.maxX - chartModel.minX
        var dateFormat = "HH:mm"
        if range <= 1800{
            dateFormat = "HH:mm"
            stamps = alignedTimestamps(start: chartModel.minX, end: chartModel.maxX, step: .minutes(5))
        }else if range <= 3600{
            stamps = alignedTimestamps(start: chartModel.minX, end: chartModel.maxX, step: .minutes(10))
            dateFormat = "HH:mm"
        }else if range <= 3600*6{
            stamps = alignedTimestamps(start: chartModel.minX, end: chartModel.maxX, step: .hours(1))
            dateFormat = "HH:mm"
        }else if range <= 3600*12{
            stamps = alignedTimestamps(start: chartModel.minX, end: chartModel.maxX, step: .hours(2))
            dateFormat = "HH:mm"
        }else if range <= 3600*24{
            stamps = alignedTimestamps(start: chartModel.minX, end: chartModel.maxX, step: .hours(4))
            dateFormat = "HH:mm"
        }else if range <= 3600*24*7{
            stamps = alignedTimestamps(start: chartModel.minX, end: chartModel.maxX, step: .days(1))
            dateFormat = "EEE"
        }else if range <= 3600*24*14{
            stamps = alignedTimestamps(start: chartModel.minX, end: chartModel.maxX, step: .days(2))
            dateFormat = "MM/dd"
        }else if range <= 3600*24*30{
            stamps = alignedTimestamps(start: chartModel.minX, end: chartModel.maxX, step: .days(5))
            dateFormat = "MM/dd"
        }else if range <= 3600*24*30*6{
            stamps = alignedTimestamps(start: chartModel.minX, end: chartModel.maxX, step: .months(1))
            dateFormat = "MMM"
        }else if range <= 3600*24*30*12{
            stamps = alignedTimestamps(start: chartModel.minX, end: chartModel.maxX, step: .months(2))
            dateFormat = "MMM"
        }else{
            let count = range/6/(3600*24*30)
            stamps = alignedTimestamps(start: chartModel.minX, end: chartModel.maxX, step: .months(Int(count)))
            dateFormat = "MMM"
        }
        return (stamps,dateFormat)
    }
    
    func drawAxisMaxMinLable(layer:CALayer,ctx:CGContext,chartModel:ChartModel,data:[ChartPointModel]){
        
        switch chartModel.bottomAxisMaxMinStyel {
            
        case .bottom(let color, let font, let offset):
            let minx = chartModel.horizontalAxisFullFrame ? 0:chartModel.chartContentInsert.left
            let miny = layer.bounds.height-(offset ?? 0)
            let minstr = chartView.delegate?.lineChartViewBottomAxisMaxMinFormatStr?(
                chartView: chartView,
                x: chartModel.minX,
                color: color,
                font: font
            ) ?? NSAttributedString(string: Date(timeIntervalSince1970: chartModel.minX).toString(format: "yyyy-MM-dd HH:mm:ss"), attributes: [.foregroundColor:color,.font:font])
            UIGraphicsPushContext(ctx)
            drawText(minstr, point: CGPoint.init(x: minx, y: miny), anchor: .minxmaxy, clampToChartContent: false)
            UIGraphicsPopContext()
            ctx.strokePath()
            let maxx = chartModel.horizontalAxisFullFrame ? layer.bounds.width:layer.bounds.width-chartModel.chartContentInsert.right
            let maxy = layer.bounds.height-(offset ?? 0)
            let maxstr = chartView.delegate?.lineChartViewBottomAxisMaxMinFormatStr?(
                chartView: chartView,
                x: chartModel.maxX,
                color: color,
                font: font
            ) ?? NSAttributedString(string: Date(timeIntervalSince1970: chartModel.maxX).toString(format: "yyyy-MM-dd HH:mm:ss"), attributes: [.foregroundColor:color,.font:font])
            UIGraphicsPushContext(ctx)
            drawText(maxstr, point: CGPoint.init(x: maxx, y: maxy), anchor: .maxxmaxy, clampToChartContent: false)
            UIGraphicsPopContext()
            ctx.strokePath()
        default:
            break
        }
        
        switch chartModel.rightAxisMaxMinStyel {
            
        case .left(let color, let font, let offset):
            let minx = layer.bounds.width - chartModel.chartContentInsert.right+(offset ?? 0)
            let miny = layer.bounds.height - chartModel.chartContentInsert.bottom
            let minstr = NSAttributedString(string: "\(chartModel.minY)", attributes: [.foregroundColor:color,.font:font])
            UIGraphicsPushContext(ctx)
            drawText(minstr, point: CGPoint.init(x: minx, y: miny), anchor: .maxxmaxy,backgroundColor: .white,cornerRadius: 0,padding: .init(top: 4, left: 8, bottom: 4, right: 8))
            UIGraphicsPopContext()
            ctx.strokePath()
            let maxx = layer.bounds.width - chartModel.chartContentInsert.right+(offset ?? 0)
            let maxy = chartModel.chartContentInsert.top
            let maxstr = NSAttributedString(string: "\(chartModel.maxY)", attributes: [.foregroundColor:color,.font:font])
            UIGraphicsPushContext(ctx)
            drawText(maxstr, point: CGPoint.init(x: maxx, y: maxy), anchor: .maxxminy,backgroundColor: .white,cornerRadius: 0,padding: .init(top: 4, left: 8, bottom: 4, right: 8))
            UIGraphicsPopContext()
            ctx.strokePath()
            break
        case .right(let color, let font, let offset):
            let minx = layer.bounds.width - chartModel.chartContentInsert.right+(offset ?? 0)
            let miny = layer.bounds.height - chartModel.chartContentInsert.bottom
            let minstr = NSAttributedString(string: "\(chartModel.minY)", attributes: [.foregroundColor:color,.font:font])
            UIGraphicsPushContext(ctx)
            drawText(minstr, point: CGPoint.init(x: minx, y: miny), anchor: .maxxmaxy,backgroundColor: .white,cornerRadius: 0,padding: .init(top: 4, left: 8, bottom: 4, right: 8))
            UIGraphicsPopContext()
            ctx.strokePath()
            let maxx = layer.bounds.width - chartModel.chartContentInsert.right+(offset ?? 0)
            let maxy = chartModel.chartContentInsert.top
            let maxstr = NSAttributedString(string: "\(chartModel.maxY)", attributes: [.foregroundColor:color,.font:font])
            UIGraphicsPushContext(ctx)
            drawText(maxstr, point: CGPoint.init(x: maxx, y: maxy), anchor: .maxxminy,backgroundColor: .white,cornerRadius: 0,padding: .init(top: 4, left: 8, bottom: 4, right: 8))
            UIGraphicsPopContext()
            ctx.strokePath()
            break
        default:break
        }
    }
    
    func drawAxisDataMaxMinLable(layer:CALayer,ctx:CGContext,chartModel:ChartModel,data:[ChartPointModel]){
        let vasivledata = data.filter({
            ($0.x>=chartModel.minX)&&($0.x<=chartModel.maxX)&&$0.dataType == .data
        })
        if vasivledata.count>0{
            let padding:UIEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
            switch chartModel.rightAxisDataMaxMinStyel {
                
            case .left(let color, let font, let offset):
                let trump = rightAxisDataMaxMinDrawY(visibleData: vasivledata,font: font, insert: padding, distance: 0)

                let ys = vasivledata.map { $0.y }
                let dataMinY = ys.min() ?? 0
                let dataMaxY = ys.max() ?? 0
                let formatMaxMin = chartView.delegate?.lineChartViewRightAxisDataMaxMinFormatStr?(
                    chartView: chartView,
                    min: dataMinY,
                    max: dataMaxY,
                    color: color,
                    font: font
                )
                let minx = layer.bounds.width - chartModel.chartContentInsert.right+(offset ?? 0)
                let minstr = formatMaxMin?.min ?? NSAttributedString(string: String(format: "%.1f", dataMinY), attributes: [.foregroundColor:color,.font:font])
                UIGraphicsPushContext(ctx)
                let minStrSize = drawText(minstr, point: CGPoint.init(x: minx, y: trump.0), anchor: .maxxcentery,backgroundColor: .white.withAlphaComponent(0.8),cornerRadius: 0,padding: padding)
                UIGraphicsPopContext()
                ctx.strokePath()
                let maxx = layer.bounds.width - chartModel.chartContentInsert.right+(offset ?? 0)
                let maxstr = formatMaxMin?.max ?? NSAttributedString(string: String(format: "%.1f", dataMaxY), attributes: [.foregroundColor:color,.font:font])
                UIGraphicsPushContext(ctx)
                let maxStrSize = drawText(maxstr, point: CGPoint.init(x: maxx, y: trump.1), anchor: .maxxcentery,backgroundColor: .white.withAlphaComponent(0.8),cornerRadius: 0,padding: padding)
                UIGraphicsPopContext()
                ctx.strokePath()
                
                ctx.saveGState()
                let pointMin = ptPointFromPoint(point: .init(x: 0, y: dataMinY))
                ctx.setLineWidth(1)
                ctx.setStrokeColor(UIColor(red: 196/255.0, green: 196/255.0, blue: 196/255.0, alpha: 1.0).withAlphaComponent(0.5).cgColor)
                ctx.setLineDash(phase: 0, lengths: [6,3])
                var startPoint = CGPoint.init(x: chartModel.chartContentInsert.left, y: pointMin.y)
                var endPoint = CGPoint.init(x: layer.bounds.width-chartModel.chartContentInsert.right-minStrSize.width+(offset ?? 0), y: pointMin.y)
                ctx.move(to: startPoint)
                ctx.addLine(to: endPoint)
                ctx.strokePath()
                
                let pointMax = ptPointFromPoint(point: .init(x: 0, y: dataMaxY))
                startPoint = CGPoint.init(x: chartModel.chartContentInsert.left, y: pointMax.y)
                endPoint = CGPoint.init(x: layer.bounds.width-chartModel.chartContentInsert.right-maxStrSize.width+(offset ?? 0), y: pointMax.y)
                ctx.move(to: startPoint)
                ctx.addLine(to: endPoint)
                ctx.strokePath()
                
                ctx.restoreGState()
                break
            case .right(let color, let font, let offset):
                let trump = rightAxisDataMaxMinDrawY(visibleData: vasivledata,font: font, insert: padding, distance: 0)

                let ys = vasivledata.map { $0.y }
                let dataMinY = ys.min() ?? 0
                let dataMaxY = ys.max() ?? 0
                let formatMaxMin = chartView.delegate?.lineChartViewRightAxisDataMaxMinFormatStr?(
                    chartView: chartView,
                    min: dataMinY,
                    max: dataMaxY,
                    color: color,
                    font: font
                )
                let minx = layer.bounds.width - chartModel.chartContentInsert.right+(offset ?? 0)
                let minstr = formatMaxMin?.min ?? NSAttributedString(string: "\(dataMinY)", attributes: [.foregroundColor:color,.font:font])
                UIGraphicsPushContext(ctx)
                let _ = drawText(minstr, point: CGPoint.init(x: minx, y: trump.0), anchor: .minxcentery,backgroundColor: .white.withAlphaComponent(0.8),cornerRadius: 0,padding: padding)
                UIGraphicsPopContext()
                ctx.strokePath()
                let maxx = layer.bounds.width - chartModel.chartContentInsert.right+(offset ?? 0)
                let maxstr = formatMaxMin?.max ?? NSAttributedString(string: "\(dataMaxY)", attributes: [.foregroundColor:color,.font:font])
                UIGraphicsPushContext(ctx)
                let _ = drawText(maxstr, point: CGPoint.init(x: maxx, y: trump.1), anchor: .minxcentery,backgroundColor: .white.withAlphaComponent(0.8),cornerRadius: 0,padding: padding)
                UIGraphicsPopContext()
                ctx.strokePath()
                
                ctx.saveGState()
                let pointMin = ptPointFromPoint(point: .init(x: 0, y: dataMinY))
                ctx.setLineWidth(1)
                ctx.setStrokeColor(UIColor(red: 196/255.0, green: 196/255.0, blue: 196/255.0, alpha: 1.0).withAlphaComponent(0.5).cgColor)
                ctx.setLineDash(phase: 0, lengths: [6,3])
                var startPoint = CGPoint.init(x: chartModel.chartContentInsert.left, y: pointMin.y)
                var endPoint = CGPoint.init(x: layer.bounds.width-chartModel.chartContentInsert.right+(offset ?? 0), y: pointMin.y)
                ctx.move(to: startPoint)
                ctx.addLine(to: endPoint)
                ctx.strokePath()
                
                let pointMax = ptPointFromPoint(point: .init(x: 0, y: dataMaxY))
                startPoint = CGPoint.init(x: chartModel.chartContentInsert.left, y: pointMax.y)
                endPoint = CGPoint.init(x: layer.bounds.width-chartModel.chartContentInsert.right+(offset ?? 0), y: pointMax.y)
                ctx.move(to: startPoint)
                ctx.addLine(to: endPoint)
                ctx.strokePath()
                
                ctx.restoreGState()
                break
            default:break
            }
        }
    }
    

    
    func rightAxisDataMaxMinDrawY(visibleData:[ChartPointModel], font:UIFont,insert:UIEdgeInsets,distance:Double)->(Double,Double){
        let strSize = NSAttributedString(string: "00.00", attributes: [.font:font]).size()
        
        let ys = visibleData.map { $0.y }
        let dataMinY = ys.min() ?? 0
        let dataMaxY = ys.max() ?? 0
        var miny = ptPointFromPoint(point: .init(x: 0, y: dataMinY)).y
        var maxy = ptPointFromPoint(point: .init(x: 0, y: dataMaxY)).y
        if miny>=layer.bounds.height-chartModel.chartContentInsert.bottom-(strSize.height*0.5+insert.bottom){
            miny = layer.bounds.height-chartModel.chartContentInsert.bottom-(strSize.height*0.5+insert.bottom)
            if maxy>=miny-(strSize.height+insert.bottom*2)-distance{
                maxy = miny-(strSize.height+insert.bottom*2)-distance
            }
        }else if maxy<=chartModel.chartContentInsert.top+(strSize.height*0.5+insert.bottom){
            maxy = chartModel.chartContentInsert.top+(strSize.height*0.5+insert.bottom)
            if miny<=maxy+(strSize.height+insert.bottom*2)+distance{
                miny = maxy+(strSize.height+insert.bottom*2)+distance
            }
        }else if miny - maxy < distance+strSize.height+insert.bottom*2+distance{
            let minyTemp = chartModel.chartContentInsert.top + (miny+maxy-2*chartModel.chartContentInsert.top)*0.5+distance*0.5+insert.bottom+strSize.height*0.5
            let maxyTemp = chartModel.chartContentInsert.top + (miny+maxy-2*chartModel.chartContentInsert.top)*0.5-distance*0.5-insert.bottom-strSize.height*0.5
            miny = minyTemp
            maxy = maxyTemp
            if miny>=layer.bounds.height-chartModel.chartContentInsert.bottom-(strSize.height*0.5+insert.bottom){
                miny = layer.bounds.height-chartModel.chartContentInsert.bottom-(strSize.height*0.5+insert.bottom)
                if maxy>=miny-(strSize.height+insert.bottom*2)-distance{
                    maxy = miny-(strSize.height+insert.bottom*2)-distance
                }
            }else if maxy<=chartModel.chartContentInsert.top+(strSize.height*0.5+insert.bottom){
                maxy = chartModel.chartContentInsert.top+(strSize.height*0.5+insert.bottom)
                if miny<=maxy+(strSize.height+insert.bottom*2)+distance{
                    miny = maxy+(strSize.height+insert.bottom*2)+distance
                }
            }
        }
        return (miny,maxy)
    }
    
    func horizontalLineAttributedText(_ line: HorizontalLine, color: UIColor, font: UIFont) -> NSAttributedString {
        if let text = chartView.delegate?.lineChartViewHLineFormatAttributeStr?(
            chartView: chartView,
            y: line.y,
            color: color,
            font: font
        ) {
            return text
        }
        return NSAttributedString(
            string: String(format: "%.1f", line.y),
            attributes: [.foregroundColor: color, .font: font]
        )
    }

    func horizontalLineAttributedText(_ line: HorizontalLine) -> NSAttributedString {
        switch line.lableStyle {
        case .top(let color, let font, _),
             .bottom(let color, let font, _),
             .left(let color, let font, _),
             .right(let color, let font, _):
            return horizontalLineAttributedText(line, color: color, font: font)
        case .none:
            return NSAttributedString(string: String(format: "%.1f", line.y))
        }
    }

    func horizontalLinesMaxMinDrawY(insert:UIEdgeInsets,distance:Double)->(Double,Double){
        guard let firstLine = chartModel.horizontalLines.first,let lastLine = chartModel.horizontalLines.last else{return (0,0)}
        let minLine = firstLine.y < lastLine.y ? firstLine : lastLine
        let maxLine = firstLine.y < lastLine.y ? lastLine : firstLine
        let minText = horizontalLineAttributedText(minLine)
        let maxText = horizontalLineAttributedText(maxLine)
        let minHeight = minText.size().height + insert.top + insert.bottom
        let maxHeight = maxText.size().height + insert.top + insert.bottom

        let dataMinY = minLine.y
        let dataMaxY = maxLine.y
        var miny = ptPointFromPoint(point: .init(x: 0, y: dataMinY)).y
        var maxy = ptPointFromPoint(point: .init(x: 0, y: dataMaxY)).y
        let minAllowedY = chartModel.chartContentInsert.top + maxHeight * 0.5
        let maxAllowedY = layer.bounds.height - chartModel.chartContentInsert.bottom - minHeight * 0.5
        let requiredDistance = maxHeight * 0.5 + minHeight * 0.5 + distance

        maxy = max(maxy, minAllowedY)
        miny = min(miny, maxAllowedY)
        if miny - maxy < requiredDistance {
            let center = (miny + maxy) * 0.5
            maxy = center - requiredDistance * 0.5
            miny = center + requiredDistance * 0.5
            if maxy < minAllowedY {
                let shift = minAllowedY - maxy
                maxy += shift
                miny += shift
            }
            if miny > maxAllowedY {
                let shift = miny - maxAllowedY
                maxy -= shift
                miny -= shift
            }
        }
        return (miny,maxy)
    }
    
    //绘制半透明框
    func drawTooltip(
        ctx: CGContext,
        center: CGPoint,
        size: CGSize,
        backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.6),
        cornerRadius: CGFloat = 6
    ) {
        
        // 1️⃣ 根据 center + size 计算 rect
        let rect = CGRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        
        // 2️⃣ 半透明背景
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        ctx.setFillColor(backgroundColor.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()
        
    }
    
    
    func getStringSize(str:String,font:UIFont)->CGSize{
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
        ]
        
        let size = (str as NSString).size(withAttributes: attrs)
        return size
    }
    //绘制文本
    func drawText(
        _ text: String,
        point: CGPoint,
        anchor:TextDrawAnchor,
        font: UIFont,
        color: UIColor
    ) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let size = (text as NSString).size(withAttributes: attrs)
        
        let ascent = font.ascender
        let descent = abs(font.descender)
        let textHeight = ascent + descent
        var origin:CGPoint
        switch anchor {
        case .minxminy:
            origin = point
        case .maxxminy:
            origin = CGPoint(
                x: point.x - size.width,
                y: point.y
            )
        case .minxmaxy:
            origin = CGPoint(
                x: point.x,
                y: point.y - size.height
            )
        case .maxxmaxy:
            origin = CGPoint(
                x: point.x - size.width,
                y: point.y - size.height
            )
        case .centerxminy:
            origin = CGPoint(
                x: point.x - size.width * 0.5,
                y: point.y
            )
        case .minxcentery:
            origin = CGPoint(
                x: point.x,
                y: point.y - size.height * 0.5
            )
        case .maxxcentery:
            origin = CGPoint(
                x: point.x - size.width,
                y: point.y - size.height * 0.5
            )
        case .centerxmaxy:
            origin = CGPoint(
                x: point.x - size.width * 0.5,
                y: point.y - size.height
            )
        case .center:
            origin = CGPoint(
                x: point.x - size.width * 0.5,
                y: point.y - size.height * 0.5
            )
        }
        
        (text as NSString).draw(at: origin, withAttributes: attrs)
    }
    
    //绘制文本
    func drawText(
        _ text: NSAttributedString,
        point: CGPoint,
        anchor: TextDrawAnchor,
        backgroundColor: UIColor? = nil,
        cornerRadius:CGFloat? = nil,
        padding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        clampToChartContent: Bool = true
    )->CGSize {
        // 1. 计算文本大小
        let textSize = text.size()
        
        // 2. 计算带内边距的背景大小
        let backgroundSize = CGSize(
            width: textSize.width + padding.left + padding.right,
            height: textSize.height + padding.top + padding.bottom
        )
        
        // 3. 根据锚点计算背景的绘制原点
        var backgroundOrigin: CGPoint
        switch anchor {
        case .minxminy:
            backgroundOrigin = point
        case .maxxminy:
            backgroundOrigin = CGPoint(
                x: point.x - backgroundSize.width,
                y: point.y
            )
        case .minxmaxy:
            backgroundOrigin = CGPoint(
                x: point.x,
                y: point.y - backgroundSize.height
            )
        case .maxxmaxy:
            backgroundOrigin = CGPoint(
                x: point.x - backgroundSize.width,
                y: point.y - backgroundSize.height
            )
        case .centerxminy:
            backgroundOrigin = CGPoint(
                x: point.x - backgroundSize.width * 0.5,
                y: point.y
            )
        case .minxcentery:
            backgroundOrigin = CGPoint(
                x: point.x,
                y: point.y - backgroundSize.height * 0.5
            )
        case .maxxcentery:
            backgroundOrigin = CGPoint(
                x: point.x - backgroundSize.width,
                y: point.y - backgroundSize.height * 0.5
            )
        case .centerxmaxy:
            backgroundOrigin = CGPoint(
                x: point.x - backgroundSize.width * 0.5,
                y: point.y - backgroundSize.height
            )
        case .center:
            backgroundOrigin = CGPoint(
                x: point.x - backgroundSize.width * 0.5,
                y: point.y - backgroundSize.height * 0.5
            )
        }
        if clampToChartContent {
            if backgroundOrigin.y<chartModel.chartContentInsert.top{
                backgroundOrigin.y = chartModel.chartContentInsert.top
            }
            if backgroundOrigin.y+backgroundSize.height>layer.bounds.height-chartModel.chartContentInsert.bottom{
                backgroundOrigin.y = layer.bounds.height-chartModel.chartContentInsert.bottom-backgroundSize.height
            }
        }
        
        // 4. 创建背景绘制区域
        let backgroundRect = CGRect(origin: backgroundOrigin, size: backgroundSize)
        
        
        // 5. 如果有背景色，绘制圆角背景 - 自动计算圆角半径
        if let bgColor = backgroundColor {
            // 自动计算圆角半径：使用背景高度的一半（胶囊形状）
            var corner = backgroundSize.height / 2
            if let cornerRadius = cornerRadius{
                corner = cornerRadius
            }
            let path = UIBezierPath(roundedRect: backgroundRect, cornerRadius: corner)
            bgColor.setFill()
            path.fill()
        }
        
        // 6. 计算文本绘制位置（在背景内部居中）
        let textOrigin = CGPoint(
            x: backgroundOrigin.x + padding.left,
            y: backgroundOrigin.y + padding.top
        )
        
        // 7. 绘制文本
        text.draw(in: CGRect(origin: textOrigin, size: textSize))
        return backgroundSize
    }
    
    func ptPointFromPoint(point:CGPoint)->CGPoint{
        let x = chartModel.chartContentInsert.left+(point.x - chartModel.minX)/(chartModel.maxX-chartModel.minX)*(layer.bounds.width - chartModel.chartContentInsert.left - chartModel.chartContentInsert.right)
        let y = layer.bounds.height - (chartModel.chartContentInsert.bottom+(point.y - chartModel.minY)/(chartModel.maxY-chartModel.minY)*(layer.bounds.height - chartModel.chartContentInsert.bottom - chartModel.chartContentInsert.top))
        return .init(x: x, y: y)
    }
    
    enum TextDrawAnchor{
        case minxminy
        case maxxminy
        case minxmaxy
        case maxxmaxy
        case centerxminy
        case minxcentery
        case maxxcentery
        case centerxmaxy
        case center
    }
    
}

extension LineChartDrawer{
    
    func getTicks(min: Double, max: Double, step: Double) -> [Double] {
        guard step > 0 else { return [] }
        guard min <= max else { return [] }
        
        var ticks: [Double] = []
        // 找到第一个 >= min 且是 step 的整数倍的刻度
        let start = ceil(min / step) * step
        
        var value = start
        while value <= max {
            ticks.append(value)
            value += step
        }
        
        return ticks
    }
    
    //获取时间轴刻度
    func alignedTimestamps(
        start: TimeInterval,
        end: TimeInterval,
        step: TimeIntervalStep,
        calendar: Calendar = .current
    ) -> [TimeInterval] {
        guard start < end else { return [] }
        var startDate = Date()
        var endDate = Date()
        if chartModel.horizontalAxisFullFrame{
            startDate = Date(timeIntervalSince1970: start - (end-start)/(layer.bounds.width-chartModel.chartContentInsert.left-chartModel.chartContentInsert.right)*chartModel.chartContentInsert.left)
            endDate = Date(timeIntervalSince1970: end+(end-start)/(layer.bounds.width-chartModel.chartContentInsert.left-chartModel.chartContentInsert.right)*chartModel.chartContentInsert.right)
        }else{
            startDate = Date(timeIntervalSince1970: start)
            endDate = Date(timeIntervalSince1970: end)
        }


        var current: Date?

        switch step {

        case .minutes(let m):
            var comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
            if let minute = comps.minute {
                let r = minute % m
                comps.minute = r == 0 ? minute : minute + (m - r)
            }
            comps.second = 0
            current = calendar.date(from: comps)

        case .hours(let h):
            var comps = calendar.dateComponents([.year, .month, .day, .hour], from: startDate)
            if let hour = comps.hour {
                let r = hour % h
                comps.hour = r == 0 ? hour : hour + (h - r)
            }
            comps.minute = 0
            comps.second = 0
            current = calendar.date(from: comps)

        case .days(let d):
            var comps = calendar.dateComponents([.year, .month, .day], from: startDate)
            if let day = comps.day {
                let r = (day - 1) % d
                comps.day = r == 0 ? day : day + (d - r)
            }
            comps.hour = 0
            comps.minute = 0
            comps.second = 0
            current = calendar.date(from: comps)

        case .months(let m):
            var comps = calendar.dateComponents([.year, .month], from: startDate)
            if let month = comps.month {
                let r = (month - 1) % m
                comps.month = r == 0 ? month : month + (m - r)
            }
            comps.day = 1
            comps.hour = 0
            comps.minute = 0
            comps.second = 0
            current = calendar.date(from: comps)
        }

        guard var date = current else { return [] }

        // 如果对齐时间仍然早于 start，推进一个 step
        while date < startDate {
            date = calendar.date(byAdding: step.calendarComponent, value: step.value, to: date)!
        }

        var result: [TimeInterval] = []
        while date <= endDate {
            result.append(date.timeIntervalSince1970)
            date = calendar.date(byAdding: step.calendarComponent, value: step.value, to: date)!
        }

        return result
    }
}

enum TimeIntervalStep {
    case minutes(Int)   // 5、10、30
    case hours(Int)     // 1、2…
    case days(Int)      // 1
    case months(Int)    // 1
}

extension TimeIntervalStep {
    var calendarComponent: Calendar.Component {
        switch self {
        case .minutes: return .minute
        case .hours:   return .hour
        case .days:    return .day
        case .months:  return .month
        }
    }

    var value: Int {
        switch self {
        case .minutes(let v),
             .hours(let v),
             .days(let v),
             .months(let v):
            return v
        }
    }
}
