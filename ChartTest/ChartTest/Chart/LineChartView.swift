//
//  LineChartView.swift
//  ChartTest
//
//  Created by Carlo on 1/13/26.
//

import UIKit

@objc protocol LineChartViewDelegate:NSObjectProtocol{
    @objc optional func lineChartViewDateModeChanged(mode:DateMode)
    @objc optional func lineChartViewXRangeChanged(min:Double,max:Double)
    @objc optional func lineChartViewYRangeChanged(min:Double,max:Double)
    //实现这个方法会覆盖lineChartViewHLineFormatStr方法
    @objc optional func lineChartViewHLineFormatAttributeStr(y:Double)->NSAttributedString
    @objc func lineChartViewHLineFormatStr(y:Double)->String

    @objc func lineChartViewTapedItemFormatStrs(x:Double,y:Double)->[String]

}


@objcMembers class LineChartView: UIView,UIGestureRecognizerDelegate {
    var delegate:LineChartViewDelegate?
    private var drawer = LineChartDrawer()
    var chartModel = ChartModel(){
        didSet{
            dealData()
        }
    }
    //用于保存手势的临时位置
    private var tempMinX:CGFloat = 0
    //用于保存手势的临时位置
    private var tempMaxX:CGFloat = 0
    //用于保存手势的临时位置
    private var pinchLocation:CGPoint = .zero
    
    private var isLabelPaning = false

    override func draw(_ layer: CALayer, in ctx: CGContext) {
                super.draw(layer, in: ctx)
        dealModels()
        drawer.draw(layer: layer,ctx: ctx, chartModel: chartModel)
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addTapGesture()
        setupPanGesture()
        setupPinchGesture()
    }
    
    func dealData(){
//        addBoundaryModel()
        let xs = chartModel.lineModel.points.map { $0.x }
        chartModel.minX = (xs.min() ?? 0)
        chartModel.maxX = (xs.max() ?? 0)
        chartModel.lineModel.points.sort(by: {$0.x<$1.x})
        dealModels()
        changeDateMode(mode: chartModel.dateMode)
        delegate?.lineChartViewDateModeChanged?(mode: chartModel.dateMode)
        delegate?.lineChartViewXRangeChanged?(min: chartModel.minX, max: chartModel.maxX)
    }
    
    func dealModels(){
        var vasivledata = [ChartPointModel]()
        let leftData = chartModel.lineModel.points.last(where: {$0.x<=chartModel.minX})
        let rightData = chartModel.lineModel.points.first(where: {$0.x>=chartModel.maxX})
//        addBoundaryModel()
        if let leftData = leftData,let rightData = rightData{
            vasivledata = chartModel.lineModel.points.filter({
                ($0.x>=leftData.x)&&($0.x<=rightData.x)
            })
        }
        if let leftData = leftData,rightData == nil{
            vasivledata = chartModel.lineModel.points.filter({
                ($0.x>=leftData.x)
            })
        }
        if leftData == nil,let rightData = rightData{
            vasivledata = chartModel.lineModel.points.filter({
                ($0.x<=rightData.x)
            })
        }
        if leftData == nil, rightData == nil{
            vasivledata = chartModel.lineModel.points
        }
        switch chartModel.yRangeType {
        case .selfAdaptAll:
            let ys = chartModel.lineModel.points.map { $0.y }
            chartModel.minY = ys.min() ?? 0
            chartModel.maxY = ys.max() ?? 0
        case .selfAdaptVisible:
            let ys = vasivledata.map { $0.y }
            chartModel.minY = ys.min() ?? 0
            chartModel.maxY = ys.max() ?? 0
        case .fixed(let min, let max):
            chartModel.minY = min
            chartModel.maxY = max
        case .selfAdaptVisibleWithMinMax(let min,let max):
            let ys = vasivledata.map { $0.y }
            let dataMin = ys.min() ?? 0
            let dataMax = ys.max() ?? 0
            chartModel.minY = min<dataMin ? min:dataMin
            chartModel.maxY = max>dataMax ? max:dataMax
        }
        chartModel.lineModel.emptyAreas = filterPointsByXDistance(vasivledata)
        delegate?.lineChartViewYRangeChanged?(min: chartModel.minY, max: chartModel.maxY)
        chartModel.lineModel.pointsShouldDraw = resampleLTTB(data: vasivledata, threshold: 200)
    }
    
    
    
    func addBoundaryModel(){
        switch chartModel.XRangeType {
        case .unlimited:
            break
        case .limitedByData:
            break
        case .distaceByNow(let double):
            chartModel.lineModel.points.removeAll(where: {$0.dataType == .boundary})
            let max = ChartPointModel()
            max.x = Date().timeIntervalSince1970
            max.y = chartModel.lineModel.points.last?.y ?? 0
            max.dataType = .boundary
            chartModel.lineModel.points.append(max)
            let min = ChartPointModel()
            min.x = Date().timeIntervalSince1970-double
            min.y = chartModel.lineModel.points.last?.y ?? 0
            min.dataType = .boundary
            chartModel.lineModel.points.append(min)
        }
        chartModel.lineModel.points.sort(by: {$0.x<$1.x})

    }
    
    //通过两点的距离获取空数据区域
    func filterPointsByXDistance(_ points: [ChartPointModel], threshold: CGFloat = 7200) -> [horizontalEmptyAreaModel] {
        guard points.count > 1 else { return [] }
        
        var result: [horizontalEmptyAreaModel] = []
        
        for i in 0..<(points.count - 1) {
            let currentPoint = points[i]
            let nextPoint = points[i + 1]
            if nextPoint.dataType != .data{
                continue
            }
            
            // 检查后一个点比前一个点的x值是否大于threshold
            if nextPoint.x - currentPoint.x > threshold {
                // 创建一个新点：x = 前一个点的x, y = 后一个点的x
                let newPoint = horizontalEmptyAreaModel.init(left: currentPoint.x, right: nextPoint.x)
                
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
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func changeXRange(min:Double,max:Double){
        switch chartModel.XRangeType {
        case .unlimited:
            self.chartModel.minX = min
            self.chartModel.maxX = max
        case .limitedByData:
            if  let firstX = chartModel.lineModel.points.first?.x, min < firstX{
                self.chartModel.minX = firstX
            }else{
                self.chartModel.minX = min
            }
            if  let lastX = chartModel.lineModel.points.last?.x, max > lastX{
                self.chartModel.maxX = lastX
            }else{
                self.chartModel.maxX = max
            }
        case .distaceByNow(let double):
            let date = Date()
            if   min < date.timeIntervalSince1970-double{
                self.chartModel.minX = date.timeIntervalSince1970-double
            }else{
                self.chartModel.minX = min
            }
            if  max > date.timeIntervalSince1970{
                self.chartModel.maxX = date.timeIntervalSince1970
            }else{
                self.chartModel.maxX = max
            }
        }
        self.setNeedsDisplay()
        delegate?.lineChartViewXRangeChanged?(min: chartModel.minX, max: chartModel.maxX)

        autoChangeDateMode()
    }
    //外部设置模式的时候自动展示当前位置合适的范围
    func changeDateMode(mode:DateMode){
        chartModel.dateMode = mode
        switch chartModel.dateMode {
        case .hour:
            chartModel.minX = chartModel.maxX-3600
        case .day:
            chartModel.minX = chartModel.maxX-3600*24
        case .week:
            chartModel.minX = chartModel.maxX-3600*24*7
        case .month:
            chartModel.minX = chartModel.maxX-3600*24*30
        case .year:
            chartModel.minX = chartModel.maxX-3600*24*30*12
        }
        self.setNeedsDisplay()
    }
    
    
    //根据显示范围自定确定日期显示模式
    private func autoChangeDateMode(){
        let range = chartModel.maxX - chartModel.minX
        if range <= 3600{
            chartModel.dateMode = .day

        }else if range <= 3600*24{
            chartModel.dateMode = .day

        }else if range <= 3600*24*7{
            chartModel.dateMode = .week

        }else if range <= 3600*24*30{
            chartModel.dateMode = .month

        }else if range <= 3600*24*30*12{
            chartModel.dateMode = .year
        }
        self.delegate?.lineChartViewDateModeChanged?(mode: chartModel.dateMode)
    }
    
    private func addTapGesture(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        
        
        if let tapedItem = chartModel.tapedItem,tapedItem.style != .normal{
            
            let location = gesture.location(in: self)
            let center = self.drawer.deteminItemDetailCenter(item: tapedItem)
            let rect = CGRect.init(x: center.x-tapedItem.detailSize.width*0.5, y: center.y-tapedItem.detailSize.height*0.5, width: tapedItem.detailSize.width, height: tapedItem.detailSize.height)
            if rect.contains(location){
                chartModel.tapedItem?.style = .normal
                chartModel.tapedItem = nil
                self.setNeedsDisplay()
                return
            }
        }
        
        let point = gesture.location(in: self)
        let dataPoint = dataPointFromPointInView(point: point)
        let item = nearestItem(in: chartModel.lineModel.pointsShouldDraw, to: dataPoint.x)
        chartModel.tapedItem?.style = .normal
        chartModel.tapedItem = item
        chartModel.tapedItem?.style = .circle(radius: 8, width: 2, color: .gray)

        self.setNeedsDisplay()
    }
    
    //数据点和view的pt之间的转换
    private func dataPointFromPointInView(point:CGPoint)->CGPoint{
        let x = chartModel.minX + (point.x-chartModel.chartContentInsert.left)/(self.bounds.width-chartModel.chartContentInsert.left-chartModel.chartContentInsert.right)*(chartModel.maxX-chartModel.minX)
        let y = chartModel.minY + (self.bounds.height-point.y-chartModel.chartContentInsert.bottom)/(self.bounds.height-chartModel.chartContentInsert.top-chartModel.chartContentInsert.bottom)*(chartModel.maxY-chartModel.minY)
        return CGPoint.init(x: x, y: y)
    }
    //获取最近点击事件的位置最近的一个数据
    private func nearestItem(
        in items: [ChartPointModel],
        to x: Double
    ) -> ChartPointModel? {

        guard !items.isEmpty else { return nil }

        return items.min {
            abs($0.x - x) < abs($1.x - x)&&$0.dataType != .boundary
        }
    }
    
    
    private func setupPanGesture() {
           let panGesture = UIPanGestureRecognizer(
               target: self,
               action: #selector(handlePan(_:))
           )
           self.addGestureRecognizer(panGesture)
        panGesture.delegate = self
           self.isUserInteractionEnabled = true
       }
    //滑动手势只有左右滑动的时候生效
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer,pan.view == self else {
                return true
            }

            let velocity = pan.velocity(in: self)

            // 横向滑动才触发
            return abs(velocity.x) > abs(velocity.y)
        }
       @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
           switch gesture.state {
           case .began:
               if let tapedItem = chartModel.tapedItem,tapedItem.style != .normal{
                   
                   let location = gesture.location(in: self)
                   let center = self.drawer.deteminItemDetailCenter(item: tapedItem)
                   let rect = CGRect.init(x: center.x-tapedItem.detailSize.width*0.5, y: center.y-tapedItem.detailSize.height*0.5, width: tapedItem.detailSize.width, height: tapedItem.detailSize.height)
                   self.isLabelPaning = rect.contains(location)
               }else{
                   self.isLabelPaning = false
               }

           case .changed:
               if isLabelPaning{
                   let point = gesture.location(in: self)
                   let dataPoint = dataPointFromPointInView(point: point)
                   let item = nearestItem(in: chartModel.lineModel.pointsShouldDraw, to: dataPoint.x)
                   chartModel.tapedItem?.style = .normal
                   chartModel.tapedItem = item
                   chartModel.tapedItem?.style = .circle(radius: 8, width: 2, color: .gray)
                   if let item = item,let firstRange = chartModel.verticalColorRnages.first(where: {$0.top>item.y&&$0.bottom<=item.y}){
                       chartModel.verticalLines = [.init(x: chartModel.tapedItem?.x ?? 0, lineStyle: .dashLine(width: 1, color: firstRange.color, lengths: [6,3]))]
                   }else{
                       chartModel.verticalLines = [.init(x: chartModel.tapedItem?.x ?? 0, lineStyle: .dashLine(width: 1, color: .lightGray, lengths: [6,3]))]
                   }
                   self.setNeedsDisplay()
               }else{
                   let translation = gesture.translation(in: self)
                   gesture.setTranslation(.zero, in: self)
                   let offset = (translation.x/self.layer.bounds.width)*(chartModel.maxX-chartModel.minX)
                   let newMaxX = self.chartModel.maxX - offset
                   let newMinX = self.chartModel.minX - offset
                   switch chartModel.XRangeType {
                   case .unlimited:
                       changeXRange(min: newMinX, max: newMaxX)
                   case .limitedByData:
                       if  let firstX = chartModel.lineModel.points.first?.x, newMinX < firstX {
                           let distance = firstX - self.chartModel.minX
                           changeXRange(min: self.chartModel.minX + distance, max: self.chartModel.maxX + distance)
                           return
                       }
                       if  let lastX = chartModel.lineModel.points.last?.x,newMaxX > lastX{
                           let distance = lastX - self.chartModel.maxX
                           changeXRange(min: self.chartModel.minX + distance, max: self.chartModel.maxX + distance)
                           return
                       }
                       changeXRange(min: self.chartModel.minX - offset, max: self.chartModel.maxX - offset)
                   case .distaceByNow(let double):
                       let date = Date()
                       if  newMinX < date.timeIntervalSince1970-double {
                           let distance = date.timeIntervalSince1970-double - self.chartModel.minX
                           changeXRange(min: self.chartModel.minX + distance, max: self.chartModel.maxX + distance)
                           return
                       }
                       if  newMaxX > date.timeIntervalSince1970{
                           let distance = date.timeIntervalSince1970 - self.chartModel.maxX
                           changeXRange(min: self.chartModel.minX + distance, max: self.chartModel.maxX + distance)
                           return
                       }
                       changeXRange(min: self.chartModel.minX - offset, max: self.chartModel.maxX - offset)
                   }
               }
               break

               
           default:
               break
           }
       }
    
    private func setupPinchGesture() {
           // 创建 Pinch 手势识别器
           let pinchGesture = UIPinchGestureRecognizer(
               target: self,
               action: #selector(handlePinch(_:))
           )
           // 将手势添加到视图
            self.addGestureRecognizer(pinchGesture)
       }
       
       @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
           guard let view = gesture.view else { return }
           
           switch gesture.state {
           case .began:
               print("Pinch 手势开始")
               pinchLocation = gesture.location(in: self)

               // 手势开始时可以做的操作
               tempMaxX = chartModel.maxX
               tempMinX = chartModel.minX
               
               
           case .changed:
               print(gesture.scale)
               let location = pinchLocation
               let locationX = (location.x-chartModel.chartContentInsert.left)/(self.bounds.width-chartModel.chartContentInsert.left-chartModel.chartContentInsert.right)*(tempMaxX-tempMinX)+tempMinX
               var newMinX = locationX - (locationX-tempMinX)*(1/gesture.scale)
               var newMaxX = locationX + (tempMaxX-locationX)*(1/gesture.scale)
               //最小一个小时，不能再放大了
               if newMaxX-newMinX<3600{
                   newMinX = (chartModel.maxX+chartModel.minX)*0.5-1800
                   newMaxX = (chartModel.maxX+chartModel.minX)*0.5+1800
                   gesture.state = .cancelled
               }
               
               switch chartModel.XRangeType {
               case .unlimited:
                   changeXRange(min: newMinX, max: newMaxX)
               case .limitedByData:
                   changeXRange(min: newMinX < (chartModel.lineModel.points.first?.x ?? 0) ? (chartModel.lineModel.points.first?.x ?? 0):newMinX, max: newMaxX > (chartModel.lineModel.points.last?.x ?? 0) ? (chartModel.lineModel.points.last?.x ?? 0):newMaxX)
               case .distaceByNow(let double):
                   let date = Date()
                   changeXRange(min: newMinX < date.timeIntervalSince1970-double ? date.timeIntervalSince1970-double:newMinX, max: newMaxX > date.timeIntervalSince1970 ? date.timeIntervalSince1970:newMaxX)
               }
           case .ended:
               print("Pinch 手势结束，最终缩放比例: \(view.transform.a)")
               // 可选：添加动画或边界检查
               
           case .cancelled:
               print("Pinch 手势被取消")
               
           default:
               break
           }
       }
    

}

//图标模型
@objc class ChartModel: NSObject{
    //图表线模型
    var lineModel:ChartLineModel = ChartLineModel()
    //图标内容的insert
    var chartContentInsert:UIEdgeInsets = .init(top: 0, left: 40, bottom: 40, right: 0)
    
    
    //顶部轴线类型
    var topAxisLineStyle:LineStyle = .line(width: 1, color: .black)
    //底部轴线类型
    var bottomAxisLineStyle:LineStyle = .line(width: 1, color: .black)
    //左部轴线类型
    var leftAxisLineStyle:LineStyle = .line(width: 1, color: .black)
    //右部轴线类型
    var rightAxisLineStyle:LineStyle = .line(width: 1, color: .black)
    
    
    //顶部轴线文字配置
    var topAxisLabelStyel:AxisLabelStyle = .top(color: .black, font: .systemFont(ofSize: 12),offset: -0)
    //底部轴线文字配置
    var bottomAxisLabelStyel:AxisLabelStyle = .bottom(color: .gray, font: .systemFont(ofSize: 12),offset: 0)
    //左部轴线文字配置
    var leftAxisLabelStyel:AxisLabelStyle = .left(color: .black, font: .systemFont(ofSize: 12),offset: -0)
    //右部轴线文字配置
    var rightAxisLabelStyel:AxisLabelStyle = .right(color: .black, font: .systemFont(ofSize: 12),offset: 0)
    

    //顶部轴线最大最小值配置
    var topAxisMaxMinStyel:AxisLabelStyle = .top(color: .black, font: .systemFont(ofSize: 12),offset: -0)
    //底部轴线最大最小值配置
    var bottomAxisMaxMinStyel:AxisLabelStyle = .bottom(color: .gray, font: .systemFont(ofSize: 12),offset:0)
    //左部轴线最大最小值配置
    var leftAxisMaxMinStyel:AxisLabelStyle = .left(color: .black, font: .systemFont(ofSize: 12),offset: -0)
    //右部轴线最大最小值配置
    var rightAxisMaxMinStyel:AxisLabelStyle = .right(color: .black, font: .systemFont(ofSize: 12),offset: -0)
    
    
    //右部数据最大最小值配置
    var rightAxisDataMaxMinStyel:AxisLabelStyle = .left(color: .black, font: .systemFont(ofSize: 12),offset: 0)
    
    
    //横向线段配置
    var horizontalLines:[HorizontalLine] = [.init(y: 60, lineStyle: .dashLine(width: 1, color: .red, lengths: [4,2]),lableStyle: .left(color: .red, font: .systemFont(ofSize: 11), offset: 0)),.init(y: 20, lineStyle: .dashLine(width: 1, color: .green, lengths: [4,2]),lableStyle: .left(color: .green, font: .systemFont(ofSize: 11), offset: 0))]
    //竖向线段配置
    var verticalLines:[VerticalLine] = []
    //竖向线段颜色配置
    var verticalColorRnages:[VerticalColorRange] = [.init(showType: .line, top: 100, bottom: 60, color: .red),
                                                    .init(showType: .line, top: 60, bottom: 20, color: .yellow),
                                                    .init(showType: .line, top: 20, bottom: 0, color: .green)]
    //日期显示模式
    var dateMode:DateMode = .day
    //图标数据显示范围，四个参数定义的区间的数据才会绘制到图表
    var minX:CGFloat = 0
    var maxX:CGFloat = 0
    var minY:CGFloat = 0
    var maxY:CGFloat = 0
    //保存当前点击的图标数据
    var tapedItem:ChartPointModel?
    //是否自适应y轴范围
    var yRangeType:YRangeType = .fixed(min: 19, max: 100)
    //是否自适应y轴范围
    var XRangeType:XRangeType = .unlimited
    //水平坐标轴是否全屏显示
    var horizontalAxisFullFrame = true
    //垂直坐标轴是否全屏显示
    var verticalAxisFullFrame = false
    //是否显示刻度尺
    var showGraduation = false
    

    
}


enum YRangeType{
    case selfAdaptAll
    case selfAdaptVisible
    case selfAdaptVisibleWithMinMax(min:Double,max:Double)
    case fixed(min:Double,max:Double)
}

enum XRangeType{
    case unlimited
    case limitedByData
    case distaceByNow(Double)
}

//图表线模型
class ChartLineModel{
//    var datalineStyle:DataLineStyle = .straight(width: 2, color: UIColor.blue)
    //线段类型
    var datalineStyle:DataLineStyle = .bezier(width: 2, color: .black)
    //数据点数组
    var points:[ChartPointModel] = [ChartPointModel]()
    
    var pointsShouldDraw:[ChartPointModel] = [ChartPointModel]()
    //数据空白区域
    var emptyAreas = [horizontalEmptyAreaModel]()


    
}

class horizontalEmptyAreaModel{
    var left:CGFloat = 0
    var right:CGFloat = 0
    var tapded = false
    init(left: CGFloat, right: CGFloat, tapded: Bool = false) {
        self.left = left
        self.right = right
        self.tapded = tapded
    }
}

//图标点模型
@objcMembers class ChartPointModel {
    enum DataType{
        case boundary
        case gap
        case data
    }
    enum Style:Equatable {
        case normal
        case circle(radius:CGFloat,width:CGFloat,color:UIColor)
        static func == (lhs: Style, rhs: Style) -> Bool {
            switch (lhs, rhs) {
            case (.normal, .normal):
                return true
                
            case  (.circle, .circle):
                return true
            default:
                return false
            }
        }
    }
    var x:Double = 0
    var y:Double = 0
    var dataType =  DataType.data
    //点击后显示的半透明块的大小
    var detailSize:CGSize = .init(width: 80, height: 40)
    var detailFont:UIFont = .systemFont(ofSize: 12)
    var detailColor:UIColor = .white
    var canTouch:Bool = false
    var style:Style = .normal
}
//横向背景颜色
class HorizontalColorRange{
    enum ShowType{
        case line
        case background
    }
    var showType:ShowType
    var left:CGFloat
    var right:CGFloat
    var color:UIColor
    init(showType: ShowType, left: CGFloat, right: CGFloat, color: UIColor) {
        self.showType = showType
        self.left = left
        self.right = right
        self.color = color
    }
    
}
//竖向背景颜色
class VerticalColorRange{
    enum ShowType{
        case line
        case background
    }
    var showType:ShowType
    var top:CGFloat
    var bottom:CGFloat
    var color:UIColor

    init(showType: ShowType, top: CGFloat, bottom: CGFloat, color: UIColor) {
        self.showType = showType
        self.top = top
        self.bottom = bottom
        self.color = color
    }
    
}
//横向指示线模型
class HorizontalLine{
    var y:CGFloat = 0
    var lineStyle:LineStyle
    var lableStyle:AxisLabelStyle
    init(y: CGFloat, lineStyle: LineStyle, lableStyle: AxisLabelStyle = .none) {
        self.y = y
        self.lineStyle = lineStyle
        self.lableStyle = lableStyle
    }
}
//竖向指示线模型
class VerticalLine{
    var x:CGFloat
    var lineStyle:LineStyle
    init(x: CGFloat, lineStyle: LineStyle) {
        self.x = x
        self.lineStyle = lineStyle
    }
}

//日期显示模型
@objc enum DateMode:Int{
    case hour = 0
    case day = 1
    case week = 2
    case month = 3
    case year = 4
}


enum DataLineStyle {
case straight(width:CGFloat,color:UIColor)
case bezier(width:CGFloat,color:UIColor)
}

enum LineStyle {
    case line(width:CGFloat,color:UIColor)
    case dashLine(width:CGFloat,color:UIColor,lengths:[CGFloat])
    case none
}
//offset 表示向外偏移量
enum AxisLabelStyle{
    case top(color:UIColor,font:UIFont,offset:CGFloat?)
    case bottom(color:UIColor,font:UIFont,offset:CGFloat?)
    case left(color:UIColor,font:UIFont,offset:CGFloat?)
    case right(color:UIColor,font:UIFont,offset:CGFloat?)
    case none
}

@objcMembers class ChartPoint:NSObject{
    var x:CGFloat = 0
    var y:CGFloat = 0
}

@objc enum XSChartType: Int {
    case radon = 1
    case temperature
    case humidity
}

//提供给oc 定义样式
extension ChartModel{
    @objc convenience init(points:[ChartPoint],type:XSChartType) {
        self.init(points: points, type: type, radonYMax: 500, radonHLine1Y: 150, radonHLine2Y: 75)
    }

    @objc convenience init(points:[ChartPoint], type:XSChartType, radonYMax: Double, radonHLine1Y: Double, radonHLine2Y: Double) {
            self.init()
            switch type{
            case .radon:
                var modelPoints = [ChartPointModel]()
                for point in points {
                    let item = ChartPointModel()
                    item.style = .normal
                    item.x = point.x
                    item.y = point.y
                    modelPoints.append(item)
                }
                lineModel.points = modelPoints
                lineModel.datalineStyle = .bezier(width: 1, color: .red)
                yRangeType = .fixed(min: 0, max: radonYMax)
                horizontalLines = [.init(y: CGFloat(radonHLine1Y), lineStyle: .dashLine(width: 1, color: .red, lengths: [4,2])),.init(y: CGFloat(radonHLine2Y), lineStyle: .dashLine(width: 1, color: .green, lengths: [4,2]))]
                verticalColorRnages = [.init(showType: .line, top: CGFloat(radonYMax), bottom: CGFloat(radonHLine1Y), color: .red),
                                                                .init(showType: .line, top: CGFloat(radonHLine1Y), bottom: CGFloat(radonHLine2Y), color: .yellow),
                                                                .init(showType: .line, top: CGFloat(radonHLine2Y), bottom: 0, color: .green)]
            case .temperature:
                var modelPoints = [ChartPointModel]()
                for point in points {
                    let item = ChartPointModel()
                    item.style = .normal
                    item.x = point.x
                    item.y = point.y
                    modelPoints.append(item)
                }
                lineModel.points = modelPoints
                yRangeType = .selfAdaptVisible
                lineModel.datalineStyle = .bezier(width: 1, color: .red)
                topAxisLineStyle = .dashLine(width: 1, color: .lightGray, lengths: [4,2])
                bottomAxisLineStyle = .dashLine(width: 1, color: .lightGray, lengths: [4,2])
                horizontalLines = []
                verticalColorRnages = [.init(showType: .line, top: 100, bottom: -50, color: .systemBlue)]
                
                
            case .humidity:
                var modelPoints = [ChartPointModel]()
                for point in points {
                    let item = ChartPointModel()
                    item.style = .normal
                    item.x = point.x
                    item.y = point.y
                    modelPoints.append(item)
                }
                lineModel.points = modelPoints
                yRangeType = .selfAdaptVisible
                lineModel.datalineStyle = .bezier(width: 1, color: .red)
                topAxisLineStyle = .none
                bottomAxisLineStyle = .dashLine(width: 1, color: .lightGray, lengths: [4,2])
                horizontalLines = []
                verticalColorRnages = [.init(showType: .line, top: 100, bottom: 0, color: .systemBlue)]
                
            default:
                break
            }
        }
    
}
