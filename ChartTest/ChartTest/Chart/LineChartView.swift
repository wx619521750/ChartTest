//
//  LineChartView.swift
//  ChartTest
//
//  Created by Carlo on 1/13/26.
//

import UIKit

@objc protocol LineChartViewDelegate:NSObjectProtocol{
    //日历模式变更回调
    @objc optional func lineChartViewDateModeChanged(chartView:LineChartView,mode:DateMode)
    @objc optional func lineChartViewXRangeChanged(chartView:LineChartView,min:Double,max:Double)
    //用户拖动、缩放或惯性滑动后的显示窗口回调
    @objc optional func lineChartViewXRangeChangedByUserInteraction(chartView:LineChartView,min:Double,max:Double)
    //显示窗口最大最小Y值回调
    @objc optional func lineChartViewYRangeChanged(chartView:LineChartView,min:Double,max:Double)
    //回调横向线段 Y 值，同时传入当前标签配置的颜色和字体
    @objc optional func lineChartViewHLineFormatAttributeStr(chartView:LineChartView,y:Double,color:UIColor,font:UIFont)->NSAttributedString
    //回调右侧最值标签 Y 值，同时传入当前标签配置的颜色和字体
    @objc optional func lineChartViewRightAxisDataMaxMinFormatStr(chartView:LineChartView,min:Double,max:Double,color:UIColor,font:UIFont)->MaxMinAttrModel
    //回调坐标轴刻度值，同时传入对应方向标签配置的颜色和字体
    @objc optional func lineChartViewAxisGraduationFormatStr(chartView:LineChartView,direction:AxisDirection,value:Double,color:UIColor,font:UIFont)->NSAttributedString?
    //回调底部首尾时间标签 X 值，同时传入当前标签配置的颜色和字体
    @objc optional func lineChartViewBottomAxisMaxMinFormatStr(chartView:LineChartView,x:Double,color:UIColor,font:UIFont)->NSAttributedString

    /// 当前点击的点的格式化字符串
    /// - Parameters:
    ///   - x: 当前点击的数据的x
    ///   - y: 当前点击的数据的x
    ///   - color: 当前点详情配置的文字颜色
    ///   - font: 当前点详情配置的字体
    /// - Returns: 格式化后的 X、Y 富文本
    @objc optional func lineChartViewTapedItemFormatStrs(chartView:LineChartView,x:Double,y:Double,color:UIColor,font:UIFont)->XYAttrModel

}


@objcMembers class LineChartView: UIView,UIGestureRecognizerDelegate {
    weak var delegate:LineChartViewDelegate?
    private lazy var drawer = LineChartDrawer(chartView: self)
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
    //标记是否正在拖动tapedItem
    private var isLabelPaning = false
    // 模拟 UIScrollView 横向减速效果
    private var decelerationDisplayLink: CADisplayLink?
    private var decelerationVelocityX: CGFloat = 0
    private var lastDecelerationTimestamp: CFTimeInterval = 0
    private let decelerationStartVelocityThreshold: CGFloat = 120
    private let decelerationStopVelocityThreshold: CGFloat = 5
    //重绘视图
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        super.draw(layer, in: ctx)
        dealModels()
        drawer.draw(layer: layer,ctx: ctx, chartModel: chartModel)
    }
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        stopDeceleration()
        super.touchesBegan(touches, with: event)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addTapGesture()
        setupPanGesture()
        setupPinchGesture()
    }
    
    func reloadData() {
        dealData()
        setNeedsDisplay()
    }

    func dealData(){
        let xs = chartModel.lineModel.points.map { $0.x }
        let now = Date().timeIntervalSince1970
        //xRangeType = .distaceByNow的时候，数据超出当前时间，初始拖动会闪动，考虑到数据一般不会超出当前时间，暂不修改
        chartModel.minX = xs.min() ?? now
        chartModel.maxX = xs.max() ?? now
        chartModel.lineModel.points.sort(by: {$0.x<$1.x})
        dealModels()
        changeDateMode(mode: chartModel.dateMode)
        delegate?.lineChartViewDateModeChanged?(chartView: self, mode: chartModel.dateMode)
        delegate?.lineChartViewXRangeChanged?(chartView: self, min: chartModel.minX, max: chartModel.maxX)
    }

    func dealModels(){
        //根据窗口大小获取可展示的数据
        var vasivledata = [ChartPointModel]()
        let points = chartModel.lineModel.points
        if !points.isEmpty {
            let referencePointCount: Int
            switch chartModel.lineModel.datalineStyle {
            case .monotoneCubic, .catmullRom:
                referencePointCount = 2
            case .straight, .bezier:
                referencePointCount = 1
            }

            let leftIndex = points.lastIndex(where: { $0.x <= chartModel.minX })
            let rightIndex = points.firstIndex(where: { $0.x >= chartModel.maxX })
            let startIndex = max(0, (leftIndex ?? 0) - (referencePointCount - 1))
            let endIndex = min(points.count - 1, (rightIndex ?? (points.count - 1)) + (referencePointCount - 1))
            vasivledata = Array(points[startIndex...endIndex])
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
        case .selfAdaptVisibleWithType(let type):
            let ys = vasivledata.map { $0.y }
            
            let minY = ys.min() ?? 0
            let maxY = ys.max() ?? 0
            let distance = maxY - minY

            var padding = distance * 0.3
            if padding<0.2{
                padding = 0.2
            }
            if padding > 2{
                padding = 2
            }
            
            chartModel.minY = minY-padding
            chartModel.maxY = maxY+padding
            if type == .humidity{
                chartModel.minY = chartModel.minY<0 ? 0:chartModel.minY
                chartModel.maxY = chartModel.maxY>100 ? 100:chartModel.maxY
            }
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
        switch chartModel.gapStyle {
        case .none:
            // 关闭 gap 后清理历史空白区域和已选中的 gap，后续不再执行 gap 相关处理。
            chartModel.lineModel.emptyAreas.removeAll()
            if chartModel.tapedItem?.dataType == .gap {
                chartModel.tapedItem = nil
            }
        case .distance(let distance):
            // 相邻数据点的 X 距离超过配置值时，将两点之间识别为 gap。
            chartModel.lineModel.emptyAreas = filterPointsByXDistance(vasivledata, threshold: distance)
        }
        delegate?.lineChartViewYRangeChanged?(chartView: self, min: chartModel.minY, max: chartModel.maxY)
        chartModel.lineModel.pointsShouldDraw = resampleLTTB(data: vasivledata, threshold: 200)
        if case .distance = chartModel.gapStyle {
            addGapModel()
        }
    }

    //通过两点的距离获取空数据区域
    func filterPointsByXDistance(_ points: [ChartPointModel], threshold: CGFloat) -> [horizontalEmptyAreaModel] {
        
        guard threshold > 0, points.count > 1 else { return [] }
        
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

    
    /// 添加gap模型，便于使用chartpointmodel一样的交互逻辑
    func addGapModel(){
        for arer in chartModel.lineModel.emptyAreas{
            let model = ChartPointModel()
            model.dataType = .gap
            model.x = (arer.left+arer.right)*0.5
            model.y = chartModel.maxY
            model.gapLeft = arer.left
            model.gapRight = arer.right
            if chartModel.tapedItem?.dataType == .gap&&model.x == chartModel.tapedItem?.x{
                model.style = chartModel.tapedItem?.style ?? .normal
            }
            chartModel.lineModel.pointsShouldDraw.append(model)
        }
        chartModel.lineModel.pointsShouldDraw.sort(by: {$0.x<$1.x})
    }

    

    /// 数据量多的时候重载样
    /// - Parameters:
    ///   - data: 总数据
    ///   - threshold: 最后剩余数据个数
    /// - Returns: 最后剩余数据数组
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
                
                if data[j].dataType == .gap{
                    result.append(data[j])
                }
            }
            result.append(selected)
            a = data.firstIndex { $0.x == selected.x && $0.y == selected.y }!
        }
        
        result.append(data.last!)
        if let minPoint = data.min(by: { $0.y < $1.y }),
           !result.contains(where: { $0 === minPoint }) {
            result.append(minPoint)
        }
        if let maxPoint = data.max(by: { $0.y < $1.y }),
           !result.contains(where: { $0 === maxPoint }) {
            result.append(maxPoint)
        }
        result.sort { $0.x < $1.x }
        return result
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopDeceleration()
    }

    
    /// 设置窗口最大最小X
    /// - Parameters:
    ///   - min: 最小X
    ///   - max: 最大X
    func changeXRange(min:Double,max:Double){
        updateXRange(min: min, max: max, isUserInteraction: false)
    }

    private func changeXRangeByUserInteraction(min: Double, max: Double) {
        updateXRange(min: min, max: max, isUserInteraction: true)
    }

    private func updateXRange(min: Double, max: Double, isUserInteraction: Bool) {
        //这里如果是通过日历手动配置窗口大小，需要根据不同的展示类型去修正传入的数据
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
        delegate?.lineChartViewXRangeChanged?(chartView: self, min: chartModel.minX, max: chartModel.maxX)
        if isUserInteraction {
            delegate?.lineChartViewXRangeChangedByUserInteraction?(
                chartView: self,
                min: chartModel.minX,
                max: chartModel.maxX
            )
        }
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
        case .none:
            break
        }
        self.setNeedsDisplay()
        delegate?.lineChartViewXRangeChanged?(chartView: self, min: chartModel.minX, max: chartModel.maxX)
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
        self.delegate?.lineChartViewDateModeChanged?(chartView: self, mode: chartModel.dateMode)
    }
    private func addTapGesture(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }
    ///处理点击事件
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        stopDeceleration()
        //判断是否有正在展示详情的数据，如何有则隐藏
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
        // 展示新的点击的数据详情
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
        return items.filter({$0.dataType == .data}).min {
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
            stopDeceleration()
            //判断是否四滑动数据详情视图
            if let tapedItem = chartModel.tapedItem,tapedItem.style != .normal{
                let location = gesture.location(in: self)
                let center = self.drawer.deteminItemDetailCenter(item: tapedItem)
                let rect = CGRect.init(x: center.x-tapedItem.detailSize.width*0.5, y: center.y-tapedItem.detailSize.height*0.5, width: tapedItem.detailSize.width, height: tapedItem.detailSize.height)
                self.isLabelPaning = rect.contains(location)
            }else{
                self.isLabelPaning = false
            }
        case .changed:
            //判断是否四滑动数据详情视图，如果是则变更正在展示的详情
            if isLabelPaning{
                let point = gesture.location(in: self)
                let dataPoint = dataPointFromPointInView(point: point)
                let item = nearestItem(in: chartModel.lineModel.pointsShouldDraw, to: dataPoint.x)
                chartModel.tapedItem?.style = .normal
                chartModel.tapedItem = item
                chartModel.tapedItem?.style = .circle(radius: 8, width: 2, color: .gray)
                self.setNeedsDisplay()
            }else{
                //如果不是，则处理曲线平移
                let translation = gesture.translation(in: self)
                gesture.setTranslation(.zero, in: self)
                let dataOffset = dataOffsetFromViewTranslation(translation.x)
                _ = shiftVisibleRange(by: dataOffset)
            }
        case .ended:
            guard !isLabelPaning else {
                isLabelPaning = false
                return
            }
            isLabelPaning = false
            startDeceleration(with: gesture.velocity(in: self).x)
        case .cancelled, .failed:
            isLabelPaning = false
            stopDeceleration()
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
            stopDeceleration()
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
            let minimumXRange = max(chartModel.minimumXRange, 0)
            if minimumXRange > 0, newMaxX - newMinX < minimumXRange {
                // 到达最小窗口时保留手指锚点，仅限制范围，不取消缩放手势。
                let originalRange = tempMaxX - tempMinX
                let anchorRatio = originalRange > 0
                    ? min(max((locationX - tempMinX) / originalRange, 0), 1)
                    : 0.5
                newMinX = locationX - minimumXRange * anchorRatio
                newMaxX = newMinX + minimumXRange
            }
            //根据不同的X轴范围处理缩放事件事件
            switch chartModel.XRangeType {
            case .unlimited:
                changeXRangeByUserInteraction(min: newMinX, max: newMaxX)
            case .limitedByData:
                changeXRangeByUserInteraction(min: newMinX < (chartModel.lineModel.points.first?.x ?? 0) ? (chartModel.lineModel.points.first?.x ?? 0):newMinX, max: newMaxX > (chartModel.lineModel.points.last?.x ?? 0) ? (chartModel.lineModel.points.last?.x ?? 0):newMaxX)
            case .distaceByNow(let double):
                let date = Date()
                changeXRangeByUserInteraction(min: newMinX < date.timeIntervalSince1970-double ? date.timeIntervalSince1970-double:newMinX, max: newMaxX > date.timeIntervalSince1970 ? date.timeIntervalSince1970:newMaxX)
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

    private func dataOffsetFromViewTranslation(_ translationX: CGFloat) -> Double {
        guard self.layer.bounds.width > 0 else { return 0 }
        return Double((translationX / self.layer.bounds.width) * CGFloat(chartModel.maxX - chartModel.minX))
    }

    @discardableResult
    private func shiftVisibleRange(by dataOffset: Double) -> Bool {
        let newMinX = chartModel.minX - dataOffset
        let newMaxX = chartModel.maxX - dataOffset
        
        switch chartModel.XRangeType {
        case .unlimited:
            changeXRangeByUserInteraction(min: newMinX, max: newMaxX)
            return true
        case .limitedByData:
            if let firstX = chartModel.lineModel.points.first?.x, newMinX < firstX {
                let distance = firstX - chartModel.minX
                if distance != 0 {
                    changeXRangeByUserInteraction(min: chartModel.minX + distance, max: chartModel.maxX + distance)
                }
                return false
            }
            if let lastX = chartModel.lineModel.points.last?.x, newMaxX > lastX {
                let distance = lastX - chartModel.maxX
                if distance != 0 {
                    changeXRangeByUserInteraction(min: chartModel.minX + distance, max: chartModel.maxX + distance)
                }
                return false
            }
            changeXRangeByUserInteraction(min: newMinX, max: newMaxX)
            return true
        case .distaceByNow(let double):
            let now = Date().timeIntervalSince1970
            if newMinX < now - double {
                let distance = now - double - chartModel.minX
                if distance != 0 {
                    changeXRangeByUserInteraction(min: chartModel.minX + distance, max: chartModel.maxX + distance)
                }
                return false
            }
            if newMaxX > now {
                let distance = now - chartModel.maxX
                if distance != 0 {
                    changeXRangeByUserInteraction(min: chartModel.minX + distance, max: chartModel.maxX + distance)
                }
                return false
            }
            changeXRangeByUserInteraction(min: newMinX, max: newMaxX)
            return true
        }
    }

    private func startDeceleration(with velocityX: CGFloat) {
        stopDeceleration()
        guard chartModel.enableDeceleration else { return }
        // 过滤手指离开瞬间的轻微抖动，避免出现非预期的小惯性位移
        guard abs(velocityX) > decelerationStartVelocityThreshold else { return }
        decelerationVelocityX = velocityX
        lastDecelerationTimestamp = 0
        let displayLink = CADisplayLink(target: self, selector: #selector(handleDecelerationTick(_:)))
        displayLink.add(to: .main, forMode: .common)
        decelerationDisplayLink = displayLink
    }

    private func stopDeceleration() {
        decelerationDisplayLink?.invalidate()
        decelerationDisplayLink = nil
        decelerationVelocityX = 0
        lastDecelerationTimestamp = 0
    }

    @objc private func handleDecelerationTick(_ displayLink: CADisplayLink) {
        if lastDecelerationTimestamp == 0 {
            lastDecelerationTimestamp = displayLink.timestamp
            return
        }
        
        let deltaTime = displayLink.timestamp - lastDecelerationTimestamp
        lastDecelerationTimestamp = displayLink.timestamp
        
        let didMove = shiftVisibleRange(by: dataOffsetFromViewTranslation(decelerationVelocityX * CGFloat(deltaTime)))
        let rate = CGFloat(pow(Double(UIScrollView.DecelerationRate.normal.rawValue), deltaTime * 1000))
        decelerationVelocityX *= rate
        
        if !didMove || abs(decelerationVelocityX) < decelerationStopVelocityThreshold {
            stopDeceleration()
        }
    }

    
}

