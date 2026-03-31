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
    
    func draw(layer:CALayer,ctx:CGContext,chartModel:ChartModel){
        self.chartModel = chartModel
        self.layer = layer
        drawAxis(layer: layer, ctx: ctx, chartModel: chartModel, data: chartModel.lineModel.pointsShouldDraw)
        drawLine(layer: layer, ctx: ctx, chartModel: chartModel, data: chartModel.lineModel.pointsShouldDraw)
        drawEmptyArea(layer: layer, ctx: ctx, chartModel: chartModel, data: chartModel.lineModel.pointsShouldDraw)
        drawAxisLable(layer: layer, ctx: ctx, chartModel: chartModel, data: chartModel.lineModel.pointsShouldDraw)
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
        
        ctx.addRect(clipRect)
        for point in chartModel.lineModel.emptyAreas{
            let point1 = ptPointFromPoint(point: .init(x: point.left, y: 0))
            let point2 = ptPointFromPoint(point: .init(x: point.right, y: 0))
            let gapRect:CGRect = .init(x: point1.x, y:chartModel.chartContentInsert.top-lineWidth*0.5, width: point2.x-point1.x, height: layer.bounds.height-chartModel.chartContentInsert.top-chartModel.chartContentInsert.bottom+lineWidth)
            ctx.addRect(gapRect)
            
        }
        ctx.clip(using: .evenOdd)

        
        switch chartModel.lineModel.datalineStyle{
        case .straight(let width, let color):
            ctx.setLineWidth(width)
            ctx.setStrokeColor(color.cgColor)
            for (index,item) in data.enumerated(){
                let pt = ptPointFromPoint(point: .init(x: item.x, y: item.y))
                if index == 0{
                    ctx.move(to: .init(x: pt.x, y: pt.y))
                }else if item.dataType == .gap{
                    ctx.move(to: .init(x: pt.x, y: pt.y))
                }else if data[index-1].dataType == .gap{
                    ctx.move(to: .init(x: pt.x, y: pt.y))
                }else{
                    ctx.addLine(to: .init(x: pt.x, y: pt.y))
                }
            }
        case .bezier(let width, let color):
            ctx.setLineWidth(width)
            ctx.setStrokeColor(color.cgColor)
            for (index,item) in data.enumerated(){
                print(item.x,item.y)
                let pt = ptPointFromPoint(point: .init(x: item.x, y: item.y))
                if index == 0{
                    ctx.move(to: .init(x: pt.x, y: pt.y))
                }else if item.dataType == .gap{
                    ctx.move(to: .init(x: pt.x, y: pt.y))
                }else if data[index-1].dataType == .gap{
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
        
        
        
        for (index,verticalColorRnage) in chartModel.verticalColorRnages.enumerated() {
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
                start: CGPoint(x: 0, y: index == 0 ?topY-lineWidth*0.5:topY),
                end: CGPoint(x: 0, y: index == chartModel.verticalColorRnages.count-1 ?bottomY+lineWidth:bottomY),
                options: []
            )
        }
        
        ctx.restoreGState()
        
    }
    
    func getLineWidth()->CGFloat{
        var lineWidth:CGFloat = 1
        switch chartModel.lineModel.datalineStyle{
        case .straight(let width, _):
          lineWidth = width
        case .bezier(let width, _):
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
            let point1 = ptPointFromPoint(point: .init(x: point.left, y: 0))
            let point2 = ptPointFromPoint(point: .init(x: point.right, y: 0))
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
        ctx.setStrokeColor(UIColor(red: 226/255.0, green: 226/255.0, blue: 226/255.0, alpha: 1.0).cgColor)
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
        for (index,horizontalLine) in chartModel.horizontalLines.enumerated() {
            ctx.saveGState()
            let clipRect = CGRect(
                x: chartModel.chartContentInsert.left,
                y: chartModel.chartContentInsert.top,
                width: layer.bounds.width - chartModel.chartContentInsert.left - chartModel.chartContentInsert.right,
                height: layer.bounds.height - chartModel.chartContentInsert.top - chartModel.chartContentInsert.bottom
            )
            
            ctx.clip(to: clipRect)
            var point = ptPointFromPoint(point: .init(x: 0, y: horizontalLine.y))
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
            UIGraphicsPushContext(ctx)
            ctx.restoreGState()
            let padding = UIEdgeInsets.init(top: 4, left: 6, bottom: 4, right: 6)
            switch horizontalLine.lableStyle {
                
            case .left(let color, let font, let offset):
                point.x = chartModel.chartContentInsert.left+(offset ?? 0)
                if point.y<chartModel.chartContentInsert.top||point.y>layer.bounds.height-chartModel.chartContentInsert.bottom{
                    continue
                }
                let trump = horizontalLinesMaxMinDrawY(font: font, insert: padding, distance: 4)
                if let str = (layer.delegate as? LineChartView)?.delegate?.lineChartViewHLineFormatAttributeStr?(y: horizontalLine.y){
                    UIGraphicsPushContext(ctx)
                    drawText(str, point:  CGPoint.init(x: chartModel.chartContentInsert.left+(offset ?? 0), y: index == 0 ?trump.1:trump.0), anchor: .maxxcentery,backgroundColor: color.withAlphaComponent(0.1),padding: padding)
                    UIGraphicsPopContext()
                }else{
                    guard  let str = (layer.delegate as? LineChartView)?.delegate?.lineChartViewHLineFormatStr(y: horizontalLine.y) else{
                        continue}
                    let attrStr = NSAttributedString.init(string: str, attributes: [.foregroundColor:color,.font:font])
                    UIGraphicsPushContext(ctx)
                    drawText(attrStr, point:  CGPoint.init(x: chartModel.chartContentInsert.left+(offset ?? 0), y: index == 0 ?trump.1:trump.0), anchor: .maxxcentery,backgroundColor: color.withAlphaComponent(0.1),padding: padding)
                    UIGraphicsPopContext()
                }
            case .right(let color, let font, let offset):
                point.x = layer.bounds.width-chartModel.chartContentInsert.right+(offset ?? 0)
                let point = ptPointFromPoint(point: .init(x: 0, y: horizontalLine.y))
                if point.y<chartModel.chartContentInsert.top||point.y>layer.bounds.height-chartModel.chartContentInsert.bottom{
                    continue
                }
                let trump = horizontalLinesMaxMinDrawY(font: font, insert: padding, distance: 4)
                
                if let str = (layer.delegate as? LineChartView)?.delegate?.lineChartViewHLineFormatAttributeStr?(y: horizontalLine.y){
                    UIGraphicsPushContext(ctx)
                    drawText(str, point:  CGPoint.init(x: layer.bounds.width-chartModel.chartContentInsert.right+(offset ?? 0), y: index == 0 ?trump.0:trump.1), anchor: .minxcentery,backgroundColor: color.withAlphaComponent(0.1),padding: padding)
                    UIGraphicsPopContext()
                }else{
                    guard  let str = (layer.delegate as? LineChartView)?.delegate?.lineChartViewHLineFormatStr(y: horizontalLine.y) else{
                        continue}
                    let attrStr = NSAttributedString.init(string: str, attributes: [.foregroundColor:color,.font:font])
                    UIGraphicsPushContext(ctx)
                    drawText(attrStr, point:  CGPoint.init(x: layer.bounds.width-chartModel.chartContentInsert.right+(offset ?? 0), y: index == 0 ?trump.0:trump.1), anchor: .minxcentery,backgroundColor: color.withAlphaComponent(0.1),padding: padding)
                    UIGraphicsPopContext()
                }
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
        if chartModel.chartContentInsert.left>point.x||point.x>layer.bounds.width-chartModel.chartContentInsert.right||chartModel.chartContentInsert.top>point.y||point.y>layer.bounds.height-chartModel.chartContentInsert.bottom{
            return
        }
        
        if item.dataType == .data{
            if let firstRange = chartModel.verticalColorRnages.first(where: {$0.top>item.y&&$0.bottom<=item.y}){
                ctx.setLineWidth(width)
                ctx.setStrokeColor(UIColor.white.cgColor)
                ctx.addEllipse(in: CGRect(
                    x: point.x - radius,
                    y: point.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                ctx.strokePath()
                
                ctx.setLineWidth(radius-width)
                ctx.setFillColor(firstRange.color.cgColor)
                ctx.addEllipse(in: CGRect(
                    x: point.x - (radius-width*0.5),
                    y: point.y - (radius-width*0.5),
                    width: (radius-width*0.5) * 2,
                    height: (radius-width*0.5) * 2
                ))
                ctx.fillPath()
                ctx.setStrokeColor(firstRange.color.cgColor)
                ctx.setLineWidth(1)
                ctx.setLineDash(phase: 0, lengths: [6,3])
                ctx.move(to: .init(x: point.x, y: chartModel.chartContentInsert.top))
                ctx.addLine(to: .init(x: point.x, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
                ctx.strokePath()
            }else{
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
            
            let strs = (layer.delegate as? LineChartView)?.delegate?.lineChartViewTapedItemFormatStrs(x: item.x, y: item.y)
            item.detailSize = deteminItemDetaiFrameSize(strs: strs ?? [])
            let detailPoint = deteminItemDetailCenter(item: item)
            drawTooltip(ctx: ctx, center: detailPoint, size: item.detailSize)
            UIGraphicsPushContext(ctx)
            
            drawText(strs?.first ?? "", point: .init(x: detailPoint.x, y: detailPoint.y-8), anchor: .center, font: item.detailFont, color: item.detailColor)
            drawText(strs?.last ?? "", point: .init(x: detailPoint.x, y: detailPoint.y+8), anchor: .center, font: item.detailFont, color: item.detailColor)
            UIGraphicsPopContext()
        }else{
            let leftStr = Date.init(timeIntervalSince1970: item.gapLeft).toString(format: "yyyy/MM/dd HH:mm")
            let rightStr = Date.init(timeIntervalSince1970: item.gapRight).toString(format: "yyyy/MM/dd HH:mm")
            
            let strs = ["GAP","\(leftStr) ~ \(rightStr)"]
            item.detailSize = deteminItemDetaiFrameSize(strs: strs)
            let detailPoint = deteminItemDetailCenter(item: item)
            drawTooltip(ctx: ctx, center: detailPoint, size: item.detailSize)
            UIGraphicsPushContext(ctx)
            
            drawText(strs.first ?? "", point: .init(x: detailPoint.x, y: detailPoint.y-8), anchor: .center, font: item.detailFont, color: item.detailColor)
            drawText(strs.last ?? "", point: .init(x: detailPoint.x, y: detailPoint.y+8), anchor: .center, font: item.detailFont, color: item.detailColor)
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
    
    func deteminItemDetaiFrameSize(strs:[String])->CGSize{
        var height:CGFloat = 0
        var width:CGFloat = 0
        for str in strs {
            let size = self.getStringSize(str: str, font: chartModel.tapedItem?.detailFont ?? .systemFont(ofSize: 12))
            height += size.height
            width = max(size.width, width)
        }
        return .init(width: width+12, height: height+12)
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
            let count = range/6/(3600*24*30)
            stamps = alignedTimestamps(start: chartModel.minX, end: chartModel.maxX, step: .months(Int(count)))
            dateFormat = "MMM"
        }
        
        switch chartModel.bottomAxisLabelStyel {
            
        case .bottom(let color, let font,let offset):
            for item in stamps{
                let x = ptPointFromPoint(point: .init(x: item, y: 0)).x
                let y = layer.bounds.height-chartModel.chartContentInsert.bottom+(offset ?? 0)
                let date = Date.init(timeIntervalSince1970: item)
                let str = date.toString(format: dateFormat)
                UIGraphicsPushContext(ctx)
                drawText(str, point: CGPoint.init(x: x, y: y), anchor: .centerxminy, font: font, color: color)
                UIGraphicsPopContext()
                if chartModel.showGraduation{
                    ctx.move(to: .init(x: x, y: layer.bounds.height-chartModel.chartContentInsert.bottom))
                    ctx.addLine(to: .init(x: x, y: layer.bounds.height-chartModel.chartContentInsert.bottom-10))
                }
            }
            ctx.strokePath()
            
        default:
            break
        }
        
        switch chartModel.bottomAxisMaxMinStyel {
            
        case .bottom(let color, let font, let offset):
            let minx = chartModel.horizontalAxisFullFrame ? 0:chartModel.chartContentInsert.left
            let miny = layer.bounds.height-(offset ?? 0)
            let mindate = Date.init(timeIntervalSince1970: chartModel.minX)
            let minstr = mindate.toString(format: "yyyy-MM-dd HH:mm:ss")
            UIGraphicsPushContext(ctx)
            drawText(minstr, point: CGPoint.init(x: minx, y: miny), anchor: .minxmaxy, font: font, color: color)
            UIGraphicsPopContext()
            ctx.strokePath()
            let maxx = chartModel.horizontalAxisFullFrame ? layer.bounds.width:layer.bounds.width-chartModel.chartContentInsert.right
            let maxy = layer.bounds.height-(offset ?? 0)
            let maxdate = Date.init(timeIntervalSince1970: chartModel.maxX)
            let maxstr = maxdate.toString(format: "yyyy-MM-dd HH:mm:ss")
            UIGraphicsPushContext(ctx)
            drawText(maxstr, point: CGPoint.init(x: maxx, y: maxy), anchor: .maxxmaxy, font: font, color: color)
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
        
        let vasivledata = data.filter({
            ($0.x>=chartModel.minX)&&($0.x<=chartModel.maxX)&&$0.dataType == .data
        })
        if vasivledata.count>0{
            let padding:UIEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0)
            switch chartModel.rightAxisDataMaxMinStyel {
                
            case .left(let color, let font, let offset):
                let trump = rightAxisDataMaxMinDrawY(font: font, insert: padding, distance: 0)
                
                let ys = data.map { $0.y }
                let dataMinY = ys.min() ?? 0
                let dataMaxY = ys.max() ?? 0
                let minx = layer.bounds.width - chartModel.chartContentInsert.right+(offset ?? 0)
                let miny = ptPointFromPoint(point: .init(x: 0, y: dataMinY)).y
                let minstr = NSAttributedString(string: String(format: "%.1f", dataMinY), attributes: [.foregroundColor:color,.font:font])
                UIGraphicsPushContext(ctx)
                drawText(minstr, point: CGPoint.init(x: minx, y: trump.0), anchor: .maxxcentery,backgroundColor: .white.withAlphaComponent(0.8),cornerRadius: 0,padding: padding)
                UIGraphicsPopContext()
                ctx.strokePath()
                let maxx = layer.bounds.width - chartModel.chartContentInsert.right+(offset ?? 0)
                let maxy = ptPointFromPoint(point: .init(x: 0, y: dataMaxY)).y
                let maxstr = NSAttributedString(string: String(format: "%.1f", dataMaxY), attributes: [.foregroundColor:color,.font:font])
                UIGraphicsPushContext(ctx)
                drawText(maxstr, point: CGPoint.init(x: maxx, y: trump.1), anchor: .maxxcentery,backgroundColor: .white.withAlphaComponent(0.8),cornerRadius: 0,padding: padding)
                UIGraphicsPopContext()
                ctx.strokePath()
                break
            case .right(let color, let font, let offset):
                let ys = data.map { $0.y }
                let dataMinY = ys.min() ?? 0
                let dataMaxY = ys.max() ?? 0
                let minx = layer.bounds.width - chartModel.chartContentInsert.right+(offset ?? 0)
                let miny = ptPointFromPoint(point: .init(x: 0, y: dataMinY)).y
                let minstr = NSAttributedString(string: "\(dataMinY)", attributes: [.foregroundColor:color,.font:font])
                UIGraphicsPushContext(ctx)
                drawText(minstr, point: CGPoint.init(x: minx, y: miny), anchor: .maxxcentery,backgroundColor: .white.withAlphaComponent(0.8),cornerRadius: 0,padding: padding)
                UIGraphicsPopContext()
                ctx.strokePath()
                let maxx = layer.bounds.width - chartModel.chartContentInsert.right+(offset ?? 0)
                let maxy = ptPointFromPoint(point: .init(x: 0, y: dataMaxY)).y
                let maxstr = NSAttributedString(string: "\(dataMaxY)", attributes: [.foregroundColor:color,.font:font])
                UIGraphicsPushContext(ctx)
                drawText(maxstr, point: CGPoint.init(x: maxx, y: maxy), anchor: .maxxcentery,backgroundColor: .white.withAlphaComponent(0.8),cornerRadius: 0,padding: padding)
                UIGraphicsPopContext()
                ctx.strokePath()
                break
            default:break
            }
        }
        
        
    }
    
    func rightAxisDataMaxMinDrawY(font:UIFont,insert:UIEdgeInsets,distance:Double)->(Double,Double){
        let strSize = NSAttributedString(string: "00.00", attributes: [.font:font]).size()
        
        let ys = chartModel.lineModel.pointsShouldDraw.map { $0.y }
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
    
    func horizontalLinesMaxMinDrawY(font:UIFont,insert:UIEdgeInsets,distance:Double)->(Double,Double){
        guard let firstLine = chartModel.horizontalLines.first,let lastLine = chartModel.horizontalLines.last else{return (0,0)}
        let strSize = NSAttributedString(string: "00.00", attributes: [.font:font]).size()
        
        
        let dataMinY = lastLine.y>firstLine.y ?  firstLine.y:lastLine.y
        let dataMaxY = lastLine.y>firstLine.y ?  lastLine.y:firstLine.y
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
        padding: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    ) {
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
        if backgroundOrigin.y<chartModel.chartContentInsert.top{
            backgroundOrigin.y = chartModel.chartContentInsert.top
        }
        if backgroundOrigin.y+backgroundSize.height>layer.bounds.height-chartModel.chartContentInsert.bottom{
            backgroundOrigin.y = layer.bounds.height-chartModel.chartContentInsert.bottom-backgroundSize.height
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
