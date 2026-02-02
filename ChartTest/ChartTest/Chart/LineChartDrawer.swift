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
    //需要绘制的数据
    var pointsShouldDraw:[ChartPointModel] = [ChartPointModel]()
    //数据空白区域
    var emptyAreas = [CGPoint]()
    func draw(layer:CALayer,ctx:CGContext,chartModel:ChartModel){
        self.chartModel = chartModel
        self.layer = layer
        dealData(data: chartModel.lineModel.points)
        drawAxis(layer: layer, ctx: ctx, chartModel: chartModel, data: pointsShouldDraw)
        drawLine(layer: layer, ctx: ctx, chartModel: chartModel, data: pointsShouldDraw)
        drawEmptyArea(layer: layer, ctx: ctx, chartModel: chartModel, data: pointsShouldDraw)
        drawAxisLable(layer: layer, ctx: ctx, chartModel: chartModel, data: pointsShouldDraw)
        drawHVLine(layer: layer, ctx: ctx, chartModel: chartModel, data: pointsShouldDraw)
        drawItemCircle(layer: layer, ctx: ctx, chartModel: chartModel, data: pointsShouldDraw)
    }
    
    //处理数据，获取可视范围数据，获取没有数据的区域，数据量多的时候重采样
    func dealData(data:[ChartPointModel]){
       
        let leftData = data.last(where: {$0.x<=chartModel.minX}) ?? ChartPointModel()
        let rightData = data.first(where: {$0.x>=chartModel.maxX}) ?? ChartPointModel()

        let vasivledata = data.filter({
            ($0.x>=leftData.x)&&($0.x<=rightData.x)
        })
        switch chartModel.yRangeType {
        case .selfAdaptAll:
            let ys = data.map { $0.y }
            chartModel.minY = ys.min() ?? 0
            chartModel.maxY = ys.max() ?? 0
        case .selfAdaptVisible:
            let ys = vasivledata.map { $0.y }
            chartModel.minY = ys.min() ?? 0
            chartModel.maxY = ys.max() ?? 0
        case .fixed(let min, let max):
            chartModel.minY = min
            chartModel.maxY = max
        }
        (layer.delegate as? LineChartView)?.delegate?.lineChartViewYRangeChanged?(min: chartModel.minY, max: chartModel.maxY)
        emptyAreas = filterPointsByXDistance(vasivledata)
        pointsShouldDraw = resampleLTTB(data: vasivledata, threshold: 200)
    }
    
    //通过两点的距离获取空数据区域
    func filterPointsByXDistance(_ points: [ChartPointModel], threshold: CGFloat = 7200) -> [CGPoint] {
        guard points.count > 1 else { return [] }
        
        var result: [CGPoint] = []
        
        for i in 0..<(points.count - 1) {
            let currentPoint = points[i]
            let nextPoint = points[i + 1]
            
            // 检查后一个点比前一个点的x值是否大于threshold
            if nextPoint.x - currentPoint.x > threshold {
                // 创建一个新点：x = 前一个点的x, y = 后一个点的x
                let newPoint = CGPoint(x: currentPoint.x, y: nextPoint.x)
                result.append(newPoint)
            }
        }
        
        return result
    }
    //数据量多的时候重载样
    func resampleLTTB(
        data: [ChartPointModel],
        threshold: Int
    ) -> [ChartPointModel] {
        guard threshold < data.count else { return data }

        let bucketSize = Double(data.count - 2) / Double(threshold - 2)
        var result: [ChartPointModel] = []
        result.append(data.first!)

        var a = 0

        for i in 0..<(threshold - 2) {
            let rangeStart = Int(Double(i + 1) * bucketSize) + 1
            let rangeEnd = Int(Double(i + 2) * bucketSize) + 1

            let nextStart = Int(Double(i + 2) * bucketSize) + 1
            let nextEnd = Int(Double(i + 3) * bucketSize) + 1

            let avgX = data[rangeStart..<min(nextEnd, data.count)]
                .map(\.x).reduce(0, +) / CGFloat(nextEnd - rangeStart)
            let avgY = data[rangeStart..<min(nextEnd, data.count)]
                .map(\.y).reduce(0, +) / CGFloat(nextEnd - rangeStart)

            var maxArea: CGFloat = -1
            var selected = data[rangeStart]
            for j in rangeStart..<min(rangeEnd, data.count) {
                let area = abs(
                    (data[a].x - avgX) * (data[j].y - data[a].y) -
                    (data[a].x - data[j].x) * (avgY - data[a].y)
                )
                if area > maxArea {
                    maxArea = area
                    selected = data[j]
                }
                //添加正在展示的点
                if data[j].x == chartModel.tapedItem?.x&&chartModel.tapedItem?.style != .normal{
                    result.append(data[j])
                }
            }
            result.append(selected)
            a = data.firstIndex { $0.x == selected.x && $0.y == selected.y }!
        }

        result.append(data.last!)
        return result
    }
    
    //绘制坐标轴
    func drawAxis(layer:CALayer,ctx:CGContext,chartModel:ChartModel,data:[ChartPointModel]){
        ctx.saveGState()
        switch chartModel.topAxisLineStyle {
        case .line(let width, let color):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width)
            ctx.move(to: CGPoint(x: 0, y: chartModel.chartContentInsert.top))
            ctx.addLine(to: CGPoint(x: layer.bounds.width, y: chartModel.chartContentInsert.top))
            ctx.strokePath()
        case .dashLine(let width, let color, let lengths):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width)
            ctx.setLineDash(phase: 0, lengths: lengths)
            ctx.move(to: CGPoint(x: 0, y: chartModel.chartContentInsert.top))
            ctx.addLine(to: CGPoint(x: layer.bounds.width, y: chartModel.chartContentInsert.top))
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
            ctx.move(to: CGPoint(x: 0, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
            ctx.addLine(to: CGPoint(x: layer.bounds.width, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
            ctx.strokePath()
        case .dashLine(let width, let color, let lengths):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width)
            ctx.setLineDash(phase: 0, lengths: lengths)
            ctx.move(to: CGPoint(x: 0, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
            ctx.addLine(to: CGPoint(x: layer.bounds.width, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
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
            ctx.move(to: CGPoint(x: chartModel.chartContentInsert.left, y: 0))
            ctx.addLine(to: CGPoint(x: chartModel.chartContentInsert.left, y: layer.bounds.height))
            ctx.strokePath()
        case .dashLine(let width, let color, let lengths):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width)
            ctx.setLineDash(phase: 0, lengths: lengths)
            ctx.move(to: CGPoint(x: chartModel.chartContentInsert.left, y: 0))
            ctx.addLine(to: CGPoint(x: chartModel.chartContentInsert.left, y: layer.bounds.height))
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
            ctx.move(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: 0))
            ctx.addLine(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: layer.bounds.height))
            ctx.strokePath()
        case .dashLine(let width, let color, let lengths):
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(width)
            ctx.setLineDash(phase: 0, lengths: lengths)
            ctx.move(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: 0))
            ctx.addLine(to: CGPoint(x: layer.bounds.width-chartModel.chartContentInsert.right, y: layer.bounds.height))
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

        let clipRect = CGRect(
            x: chartModel.chartContentInsert.left,
            y: chartModel.chartContentInsert.top,
            width: layer.bounds.width - chartModel.chartContentInsert.left - chartModel.chartContentInsert.right,
            height: layer.bounds.height - chartModel.chartContentInsert.top - chartModel.chartContentInsert.bottom
        )

        ctx.clip(to: clipRect)

        
        switch chartModel.lineModel.datalineStyle{
        case .straight(let width, let color):
            ctx.setLineWidth(width)
            ctx.setStrokeColor(color.cgColor)
            for (index,item) in data.enumerated(){
                let pt = ptPointFromPoint(point: .init(x: item.x, y: item.y))
                if index == 0{
                    ctx.move(to: .init(x: pt.x, y: pt.y))
                }
                ctx.addLine(to: .init(x: pt.x, y: pt.y))
            }
        case .bezier(let width, let color):
            ctx.setLineWidth(width)
            ctx.setStrokeColor(color.cgColor)
            for (index,item) in data.enumerated(){
                print(item.x,item.y)
                let pt = ptPointFromPoint(point: .init(x: item.x, y: item.y))
                if index == 0{
                    ctx.move(to: .init(x: pt.x, y: pt.y))
                }else{
                    let preItem = data[index-1]
                    let prePt = ptPointFromPoint(point: .init(x: preItem.x, y: preItem.y))
                    let t = 0.5
                    ctx.addCurve(to: .init(x: pt.x, y: pt.y), control1: .init(x: prePt.x+(pt.x-prePt.x)*t, y: prePt.y), control2: .init(x: pt.x-(pt.x-prePt.x)*t, y: pt.y))
                }
            }
        }
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        for verticalColorRnage in chartModel.verticalColorRnages {
            let toppt = ptPointFromPoint(point: .init(x: 0, y: verticalColorRnage.top ))
            let bottompt = ptPointFromPoint(point: .init(x: 0, y: verticalColorRnage.bottom ))

            let topY = toppt.y
            let bottomY = bottompt.y
            let colors = [
                verticalColorRnage.color.cgColor,
                verticalColorRnage.color.cgColor
            ]
            
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0, 1]
            )!
            
            ctx.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: topY),
                end: CGPoint(x: 0, y: bottomY),
                options: []
            )
        }
        
        ctx.restoreGState()
        
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
        ctx.setFillColor(UIColor.lightGray.cgColor)
        for point in emptyAreas{
            let point1 = ptPointFromPoint(point: .init(x: point.x, y: 0))
            let point2 = ptPointFromPoint(point: .init(x: point.y, y: 0))
            ctx.addRect(.init(x: point1.x, y:chartModel.chartContentInsert.top, width: point2.x-point1.x, height: layer.bounds.height-chartModel.chartContentInsert.top-chartModel.chartContentInsert.bottom))
        }
        ctx.fillPath()
        ctx.restoreGState()
        
    }
    
    
    //绘制水平垂直的线条
    func drawHVLine(layer:CALayer,ctx:CGContext,chartModel:ChartModel,data:[ChartPointModel]){
        ctx.saveGState()
        for horizontalLine in chartModel.horizontalLines {
            let point = ptPointFromPoint(point: .init(x: 0, y: horizontalLine.y))
            let clipRect = CGRect(
                x: chartModel.chartContentInsert.left,
                y: chartModel.chartContentInsert.top,
                width: layer.bounds.width - chartModel.chartContentInsert.left - chartModel.chartContentInsert.right,
                height: layer.bounds.height - chartModel.chartContentInsert.top - chartModel.chartContentInsert.bottom
            )

            ctx.clip(to: clipRect)
            switch horizontalLine.lineStyle {
            case .line(let width, let color):
                ctx.setLineWidth(width)
                ctx.setStrokeColor(color.cgColor)
            case .dashLine(let width, let color, let lengths):
                ctx.setLineWidth(width)
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineDash(phase: 0, lengths: lengths)
            case .none:
                return
            }
            let startPoint = CGPoint.init(x: chartModel.chartContentInsert.left, y: point.y)
            let endPoint = CGPoint.init(x: layer.bounds.width-chartModel.chartContentInsert.right, y: point.y)
            ctx.move(to: startPoint)
            ctx.addLine(to: endPoint)
            ctx.strokePath()
        }
        ctx.restoreGState()
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
            case .dashLine(let width, let color, let lengths):
                ctx.setLineWidth(width)
                ctx.setStrokeColor(color.cgColor)
                ctx.setLineDash(phase: 0, lengths: lengths)
            case .none:
                return
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
        ctx.saveGState()
        let point = ptPointFromPoint(point: .init(x: item.x, y: item.y))
        let clipRect = CGRect(
            x: chartModel.chartContentInsert.left,
            y: chartModel.chartContentInsert.top,
            width: layer.bounds.width - chartModel.chartContentInsert.left - chartModel.chartContentInsert.right,
            height: layer.bounds.height - chartModel.chartContentInsert.top - chartModel.chartContentInsert.bottom
        )

        ctx.clip(to: clipRect)
        ctx.setLineWidth(width)
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
        ctx.restoreGState()
        let strs = (layer.delegate as? LineChartView)?.delegate?.lineChartViewTapedItemFormatStrs?(x: item.x, y: item.y)
        let detailPoint = deteminItemDetailCenter(item: item)
        item.detailSize = deteminItemDetaiFrameSize(strs: strs ?? [])
        drawTooltip(ctx: ctx, center: detailPoint, size: item.detailSize)
        UIGraphicsPushContext(ctx)

        drawText(strs?.first ?? "", point: .init(x: detailPoint.x, y: detailPoint.y-6), anchor: .center, font: item.detailFont, color: item.detailColor)
        drawText(strs?.last ?? "", point: .init(x: detailPoint.x, y: detailPoint.y+6), anchor: .center, font: item.detailFont, color: item.detailColor)
//        drawTextVisuallyCentered("x=\(round(detailPoint.x))", center: .init(x: detailPoint.x, y: detailPoint.y-6), font: .systemFont(ofSize: 12), color: .white)
//        drawTextVisuallyCentered("y=   \(round(detailPoint.y))", center: .init(x: detailPoint.x, y: detailPoint.y+6), font: .systemFont(ofSize: 12), color: .white)
        UIGraphicsPopContext()
        
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
    
    func deteminItemDetaiFrameSize(strs:[String])->CGSize{
        var height:CGFloat = 0
        var width:CGFloat = 0
        for str in strs {
            let size = self.getStringSize(str: str, font: chartModel.tapedItem?.detailFont ?? .systemFont(ofSize: 12))
            height += size.height
            width = max(size.width, width)
        }
        return .init(width: width+12, height: height+24)
    }
    
    //绘制轴线的刻度文本
    func drawAxisLable(layer:CALayer,ctx:CGContext,chartModel:ChartModel,data:[ChartPointModel]){
       
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
            stamps = alignedTimestamps(start: chartModel.minX, end: chartModel.maxX, step: .months(2))
            dateFormat = "MMM"
        }
        
        switch chartModel.bottomAxisLabelStyel {
        case .top(_, _,_):
            break
        case .bottom(let color, let font,let offset):
            for item in stamps{
                let x = chartModel.chartContentInsert.left+(item - chartModel.minX)/(chartModel.maxX-chartModel.minX)*(layer.bounds.width - chartModel.chartContentInsert.left - chartModel.chartContentInsert.right)
                let y = layer.bounds.height-chartModel.chartContentInsert.bottom+(offset ?? 0)
                let date = Date.init(timeIntervalSince1970: item)
                let str = date.toString(format: dateFormat)
                UIGraphicsPushContext(ctx)
                drawText(str, point: CGPoint.init(x: x, y: y), anchor: .center, font: font, color: color)
                UIGraphicsPopContext()
                ctx.move(to: .init(x: x, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
                ctx.addLine(to: .init(x: x, y: layer.bounds.height-chartModel.chartContentInsert.bottom-10))
            }
            ctx.strokePath()
            
        case .left(_, _,_):
            break
        case .right(_, _,_):
            break
        }
        
        switch chartModel.rightAxisLabelStyel {
        case .top(_, _,_):
            break
        case .bottom(_, _,_):
            break
        case .left( _,  _,_):
            break
        case .right(let color, let font,let offset):
            ctx.saveGState()
            for horizontalLine in chartModel.horizontalLines {
                let point = ptPointFromPoint(point: .init(x: 0, y: horizontalLine.y))
                UIGraphicsPushContext(ctx)
                let str = (layer.delegate as? LineChartView)?.delegate?.lineChartViewHLineFormatStr?(y: horizontalLine.y) ?? ""
                drawText(str, point:  CGPoint.init(x: layer.bounds.width-chartModel.chartContentInsert.right*0.5+(offset ?? 0), y: point.y), anchor: .center, font: font, color: color)
                UIGraphicsPopContext()

            }
            ctx.restoreGState()
            break
        }
        
        switch chartModel.bottomAxisMaxMinStyel {
        case .top( _,  _,_):
            break
        case .bottom(let color, let font, let offset):
            let minx = chartModel.chartContentInsert.left+(chartModel.minX - chartModel.minX)/(chartModel.maxX-chartModel.minX)*(layer.bounds.width - chartModel.chartContentInsert.left - chartModel.chartContentInsert.right)
                let miny = layer.bounds.height+(offset ?? 0)
                let mindate = Date.init(timeIntervalSince1970: chartModel.minX)
                let minstr = mindate.toString(format: "yyyy/MM/dd HH:mm:ss")
                UIGraphicsPushContext(ctx)
            drawText(minstr, point: CGPoint.init(x: minx, y: miny), anchor: .minxcentery, font: font, color: color)
                UIGraphicsPopContext()
            ctx.strokePath()
            let maxx = chartModel.chartContentInsert.left+(chartModel.maxX - chartModel.minX)/(chartModel.maxX-chartModel.minX)*(layer.bounds.width - chartModel.chartContentInsert.left - chartModel.chartContentInsert.right)
                let maxy = layer.bounds.height+(offset ?? 0)
                let maxdate = Date.init(timeIntervalSince1970: chartModel.minX)
                let maxstr = maxdate.toString(format: "yyyy/MM/dd HH:mm:ss")
                UIGraphicsPushContext(ctx)
            drawText(maxstr, point: CGPoint.init(x: maxx, y: maxy), anchor: .maxxcentery, font: font, color: color)
                UIGraphicsPopContext()
            ctx.strokePath()
        case .left( _,  _,_):
            break
        case .right( _,  _,_):
            break
        }
        
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
                x: point.x - size.width / 2,
                y: point.y - size.height / 2
            )
        }

        (text as NSString).draw(at: origin, withAttributes: attrs)
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
    //获取时间轴刻度
    func alignedTimestamps(
        start: TimeInterval,
        end: TimeInterval,
        step: TimeIntervalStep,
        calendar: Calendar = .current
    ) -> [TimeInterval] {
        guard start < end else { return [] }

        let startDate = Date(timeIntervalSince1970: start)
        let endDate = Date(timeIntervalSince1970: end)

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
