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
        self.drawer.draw(layer: layer,ctx: ctx, chartModel: chartModel)
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
        chartModel.lineModel.points.sort(by: {$0.x<$1.x})
        let xs = chartModel.lineModel.points.map { $0.x }
        chartModel.minX = (xs.min() ?? 0)
        chartModel.maxX = (xs.max() ?? 0)
        changeDateMode(mode: chartModel.dateMode)
        delegate?.lineChartViewDateModeChanged?(mode: chartModel.dateMode)
        delegate?.lineChartViewXRangeChanged?(min: chartModel.minX, max: chartModel.maxX)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func changeXRange(min:Double,max:Double){
        self.chartModel.minX = min
        self.chartModel.maxX = max
        self.setNeedsDisplay()
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
        let item = nearestItem(in: self.drawer.pointsShouldDraw, to: dataPoint.x)
        chartModel.tapedItem?.style = .normal
        chartModel.tapedItem = item
        chartModel.tapedItem?.style = .circle(radius: 4, width: 2, color: .gray)
        chartModel.verticalLines = [.init(x: chartModel.tapedItem?.x ?? 0, lineStyle: .dashLine(width: 1, color: .lightGray, lengths: [4,2]))]
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
            abs($0.x - x) < abs($1.x - x)
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
                   let item = nearestItem(in: self.drawer.pointsShouldDraw, to: dataPoint.x)
                   chartModel.tapedItem?.style = .normal
                   chartModel.tapedItem = item
                   chartModel.tapedItem?.style = .circle(radius: 4, width: 2, color: .gray)
                   chartModel.verticalLines = [.init(x: chartModel.tapedItem?.x ?? 0, lineStyle: .dashLine(width: 1, color: .lightGray, lengths: [4,2]))]
                   self.setNeedsDisplay()
               }else{
                   let translation = gesture.translation(in: self)
                   gesture.setTranslation(.zero, in: self)
                   let offset = (translation.x/self.layer.bounds.width)*(chartModel.maxX-chartModel.minX)
                   let newMaxX = self.chartModel.maxX - offset
                   let newMinX = self.chartModel.minX - offset
                   if  newMinX < (chartModel.lineModel.points.first?.x ?? 0) || newMaxX > (chartModel.lineModel.points.last?.x ?? 0){
                       return
                   }
                   self.chartModel.maxX -= offset
                   self.chartModel.minX -= offset
                   self.setNeedsDisplay()
                   delegate?.lineChartViewXRangeChanged?(min: chartModel.minX, max: chartModel.maxX)
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
               
               chartModel.minX = newMinX < (chartModel.lineModel.points.first?.x ?? 0) ? (chartModel.lineModel.points.first?.x ?? 0):newMinX
               chartModel.maxX = newMaxX > (chartModel.lineModel.points.last?.x ?? 0) ? (chartModel.lineModel.points.last?.x ?? 0):newMaxX
               autoChangeDateMode()
               setNeedsDisplay()
               delegate?.lineChartViewXRangeChanged?(min: chartModel.minX, max: chartModel.maxX)
           case .ended:
               print("Pinch 手势结束，最终缩放比例: \(view.transform.a)")
               // 可选：添加动画或边界检查
               
           case .cancelled:
               print("Pinch 手势被取消")
               
           default:
               break
           }
       }
    
    //根据显示范围自定确定日期显示模式
    private func autoChangeDateMode(){
        let range = chartModel.maxX - chartModel.minX
        if range <= 3600{
            chartModel.dateMode = .hour

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
}

//图标模型
@objc class ChartModel: NSObject{
    //图表线模型
    var lineModel:ChartLineModel = ChartLineModel()
    //图标内容的insert
    var chartContentInsert:UIEdgeInsets = .init(top: 10, left: 10, bottom: 40, right: 40)
    //顶部轴线类型
    var topAxisLineStyle:LineStyle = .line(width: 1, color: .black)
    //底部轴线类型
    var bottomAxisLineStyle:LineStyle = .line(width: 1, color: .black)
    //左部轴线类型
    var leftAxisLineStyle:LineStyle = .line(width: 1, color: .black)
    //右部轴线类型
    var rightAxisLineStyle:LineStyle = .line(width: 1, color: .black)
    //顶部轴线文字配置
    var topAxisLabelStyel:AxisLabelStyle = .top(color: .black, font: .systemFont(ofSize: 12),offset: -12)
    //底部轴线文字配置
    var bottomAxisLabelStyel:AxisLabelStyle = .bottom(color: .gray, font: .systemFont(ofSize: 12),offset: 12)
    //左部轴线文字配置
    var leftAxisLabelStyel:AxisLabelStyle = .left(color: .black, font: .systemFont(ofSize: 12),offset: -0)
    //右部轴线文字配置
    var rightAxisLabelStyel:AxisLabelStyle = .right(color: .black, font: .systemFont(ofSize: 12),offset: 0)
    //顶部轴线文字配置
    var topAxisMaxMinStyel:AxisLabelStyle = .top(color: .black, font: .systemFont(ofSize: 12),offset: -0)
    //底部轴线文字配置
    var bottomAxisMaxMinStyel:AxisLabelStyle = .bottom(color: .gray, font: .systemFont(ofSize: 12),offset: -12)
    //左部轴线文字配置
    var leftAxisMaxMinStyel:AxisLabelStyle = .left(color: .black, font: .systemFont(ofSize: 12),offset: -0)
    //右部轴线文字配置
    var rightAxisMaxMinStyel:AxisLabelStyle = .right(color: .black, font: .systemFont(ofSize: 12),offset: 0)
    //横向线段配置
    var horizontalLines:[HorizontalLine] = [.init(y: 60, lineStyle: .dashLine(width: 1, color: .red, lengths: [4,2])),.init(y: 20, lineStyle: .dashLine(width: 1, color: .green, lengths: [4,2]))]
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
    var yRangeType:YRangeType = .fixed(min: -30, max: 200)
    
    
}


enum YRangeType{
    case selfAdaptAll
    case selfAdaptVisible
    case fixed(min:Double,max:Double)
}

//图表线模型
class ChartLineModel{
//    var datalineStyle:DataLineStyle = .straight(width: 2, color: UIColor.blue)
    //线段类型
    var datalineStyle:DataLineStyle = .bezier(width: 2, color: .blue)
    //数据点数组
    var points:[ChartPointModel] = [ChartPointModel]()
    
    var pointsShouldDraw:[ChartPointModel] = [ChartPointModel]()

    
}

//图标点模型
@objcMembers class ChartPointModel {
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
    init(y: CGFloat, lineStyle: LineStyle) {
        self.y = y
        self.lineStyle = lineStyle
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
    case hour = 1
    case day = 2
    case week = 3
    case month = 4
    case year = 5
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



//提供给oc 定义样式
extension ChartModel{
    @objc convenience init(points:[ChartPoint],type:Int) {
        self.init()
        switch type{
        case 1:
            var points = [ChartPointModel]()
            for point in points{
                let item = ChartPointModel()
                item.style = .normal
                item.x = point.x
                item.y = point.y
                item.style = .normal
                item.detailSize = .init(width: 10, height: 20)
                points.append(item)
            }
            lineModel.points = points
            lineModel.datalineStyle = .straight(width: 1, color: .red)
        case 2:
            var points = [ChartPointModel]()
            for point in points{
                let item = ChartPointModel()
                item.style = .normal
                item.x = point.x
                item.y = point.y
                item.style = .normal
                item.detailSize = .init(width: 10, height: 20)
                points.append(item)
            }
            lineModel.points = points
            lineModel.datalineStyle = .straight(width: 1, color: .red)
            
        default:
            break
        }
    }
    
    
}
