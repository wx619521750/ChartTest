//
//  ViewController.swift
//  ChartTest
//
//  Created by Carlo on 1/13/26.
//

import UIKit

class ViewController: UIViewController,SegmentViewDelegate,LineChartViewDelegate {

    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .lightGray
        view.addSubview(scrollView)
        scrollView.addSubview(lineChartView)
        scrollView.addSubview(segmentView)
        scrollView.addSubview(segmentView1)
        scrollView.addSubview(minDatePicker)
        scrollView.addSubview(maxDatePicker)
        initData()
    }
    
    func initData(){
        
        let chartModel = ChartModel()
        var points = [ChartPointModel]()
        if let data = loadData() {
            var x:Double = 0
            var y:Double = 0
            for (key,value) in data{
                for str in value{
                    var strs = str.components(separatedBy: ",")
                    let dateStr = key+strs[0]
                    x = Date.dateFromString(str: dateStr, format: "yyyyMMddHHmmss")?.timeIntervalSince1970 ?? 0
                    y = Double(strs[1]) ?? 0
                    let item = ChartPointModel()
                    item.style = .normal
                    item.x = x
                    item.y = y
                    points.append(item)
                }
            }
        }
        chartModel.lineModel.points = points

        lineChartView.chartModel = chartModel
        segmentView1.selectIndex(index: 0, withDelegate: true)
    }
    
    func loadData() -> [String: [String]]? {
        guard let url = Bundle.main.url(
            forResource: "aaa",
            withExtension: "json"
        ) else {
            print("文件不存在")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let dict = try JSONDecoder().decode(
                [String: [String]].self,
                from: data
            )
            return dict
        } catch {
            print("解析失败:", error)
            return nil
        }
    }

    
    lazy var lineChartView: LineChartView = {
        let view = LineChartView()
        view.frame = .init(x: 20, y: 100, width: UIScreen.main.bounds.width-40, height: 240)
        view.backgroundColor = .white
        view.delegate = self
        return view
    }()
    
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.contentSize = .init(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height*2)
        view.frame = .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        return view
    }()
    
    lazy var segmentView: SegmentView = {
        let view = SegmentView.init(frame: .init(x: 20, y: 340, width: UIScreen.main.bounds.width-40, height: 44))
        view.titles = ["hour","day","week","month","year"]
        view.tag = 101

        view.delegate = self
        return view
    }()
    
    lazy var segmentView1: SegmentView = {
        let view = SegmentView.init(frame: .init(x: 20, y: 340+44, width: UIScreen.main.bounds.width-40, height: 44))
        view.titles = ["氡气","温度","湿度"]
        view.tag = 102
        view.delegate = self
        return view
    }()
    
    lazy var minDatePicker: UIDatePicker = {
        let view = UIDatePicker()
        view.frame = .init(x: 20, y: 384+44, width: UIScreen.main.bounds.width-40, height: 44)
        view.datePickerMode = .dateAndTime
        view.addTarget(self,
                            action: #selector(dateChanged(_:)),
                            for: .valueChanged)
        return view
    }()
    lazy var maxDatePicker: UIDatePicker = {
        let view = UIDatePicker()
        view.frame = .init(x: 20, y: 428+44, width: UIScreen.main.bounds.width-40, height: 44)
        view.datePickerMode = .dateAndTime
        view.addTarget(self,
                            action: #selector(dateChanged(_:)),
                            for: .valueChanged)
        return view
    }()
    
    @objc func dateChanged(_ sender: UIDatePicker) {
        let selectedDate = sender.date
        print("选择的日期: \(selectedDate)")

        lineChartView.changeXRange(min: minDatePicker.date.timeIntervalSince1970, max:  maxDatePicker.date.timeIntervalSince1970)
    }
    
    func segmentView(_ segmentView: SegmentView, selectedIndex: Int) {
        if segmentView.tag == 101{
            
            switch selectedIndex{
            case 0:
                lineChartView.changeDateMode(mode: .hour)
            case 1:
                lineChartView.changeDateMode(mode: .day)
            case 2:
                lineChartView.changeDateMode(mode: .week)
            case 3:
                lineChartView.changeDateMode(mode: .month)
            case 4:
                lineChartView.changeDateMode(mode: .year)
            default:break
                
            }
        }else{
//            switch selectedIndex{
//            case 0:
//                lineChartView.chartModel.chartContentInsert = .init(top: 0, left: 40, bottom: 40, right: 0)
//                lineChartView.chartModel.yRangeType = .selfAdaptVisibleWithMinMax(min: 0, max: 60)
//                
//                lineChartView.chartModel.lineModel.datalineStyle = .bezier(width: 2, color: .black)
//                
//                lineChartView.chartModel.topAxisLineStyle = .none
//                lineChartView.chartModel.rightAxisLineStyle = .none
//                lineChartView.chartModel.leftAxisLineStyle = .none
//                lineChartView.chartModel.bottomAxisLineStyle = .dashLine(width: 1, color: .lightGray, lengths: [6,3])
//                
//                lineChartView.chartModel.rightAxisMaxMinStyel = .none
//                
//                lineChartView.chartModel.rightAxisDataMaxMinStyel = .left(color: .black, font: .systemFont(ofSize: 12),offset: 0)
//                
//                lineChartView.chartModel.horizontalLines = [.init(y: 60, lineStyle: .dashLine(width: 1, color: .red, lengths: [4,2]),lableStyle: .left(color: .red, font: .systemFont(ofSize: 11), offset: 0)),.init(y: 20, lineStyle: .dashLine(width: 1, color: .green, lengths: [4,2]),lableStyle: .left(color: .green, font: .systemFont(ofSize: 11), offset: 0))]
//                //竖向线段颜色配置
//                lineChartView.chartModel.verticalColorRnages = [.init(showType: .line, top: 100, bottom: 60, color: .red),
//                                                                .init(showType: .line, top: 60, bottom: 20, color: .yellow),
//                                                                .init(showType: .line, top: 20, bottom: 0, color: .green)]
//                
//                
//                lineChartView.chartModel.horizontalAxisFullFrame = true
//                //垂直坐标轴是否全屏显示
//                lineChartView.chartModel.verticalAxisFullFrame = false
//                //是否显示刻度尺
//                lineChartView.chartModel.showGraduation = false
//                lineChartView.setNeedsDisplay()
//            case 1:
//                lineChartView.chartModel.chartContentInsert = .init(top: 0, left: 0, bottom: 40, right: 0)
//                lineChartView.chartModel.yRangeType = .selfAdaptVisible
//                
//                lineChartView.chartModel.lineModel.datalineStyle = .bezier(width: 2, color: .black)
//
//                
//                lineChartView.chartModel.topAxisLineStyle = .none
//                lineChartView.chartModel.rightAxisLineStyle = .none
//                lineChartView.chartModel.leftAxisLineStyle = .none
//                lineChartView.chartModel.bottomAxisLineStyle = .dashLine(width: 1, color: .lightGray, lengths: [6,3])
//                
//                lineChartView.chartModel.rightAxisMaxMinStyel = .none
//                
//                lineChartView.chartModel.rightAxisDataMaxMinStyel = .none
//                
//                lineChartView.chartModel.horizontalLines = []
//                //竖向线段颜色配置
//                lineChartView.chartModel.verticalColorRnages = [.init(showType: .line, top: 100, bottom: 60, color: .red),
//                                                                .init(showType: .line, top: 60, bottom: 20, color: .yellow),
//                                                                .init(showType: .line, top: 20, bottom: 0, color: .green)]
//                
//                
//                lineChartView.chartModel.horizontalAxisFullFrame = true
//                //垂直坐标轴是否全屏显示
//                lineChartView.chartModel.verticalAxisFullFrame = false
//                //是否显示刻度尺
//                lineChartView.chartModel.showGraduation = false
//                lineChartView.setNeedsDisplay()
//            case 2:
//                lineChartView.chartModel.chartContentInsert = .init(top: 0, left: 0, bottom: 40, right: 0)
//                lineChartView.chartModel.yRangeType = .selfAdaptVisible
//                
//                lineChartView.chartModel.lineModel.datalineStyle = .bezier(width: 2, color: .black)
//
//                
//                lineChartView.chartModel.topAxisLineStyle = .none
//                lineChartView.chartModel.rightAxisLineStyle = .none
//                lineChartView.chartModel.leftAxisLineStyle = .none
//                lineChartView.chartModel.bottomAxisLineStyle = .dashLine(width: 1, color: .lightGray, lengths: [6,3])
//                
//                lineChartView.chartModel.rightAxisMaxMinStyel = .none
//                
//                lineChartView.chartModel.rightAxisDataMaxMinStyel = .none
//                
//                lineChartView.chartModel.horizontalLines = []
//                //竖向线段颜色配置
//                lineChartView.chartModel.verticalColorRnages = [.init(showType: .line, top: 100, bottom: 0, color: .red)]
//                
//                
//                lineChartView.chartModel.horizontalAxisFullFrame = true
//                //垂直坐标轴是否全屏显示
//                lineChartView.chartModel.verticalAxisFullFrame = false
//                //是否显示刻度尺
//                lineChartView.chartModel.showGraduation = false
//                lineChartView.setNeedsDisplay()
//            default:break
//            }
            
            switch selectedIndex{
            case 0:
                lineChartView.chartModel.chartContentInsert = .init(top: 0, left: 40, bottom: 40, right: 0)
                lineChartView.chartModel.yRangeType = .selfAdaptVisibleWithMinMax(min: 0, max: 60)
//                lineChartView.chartModel.yRangeType = .fixed(min: 19, max: 60)

                lineChartView.chartModel.lineModel.datalineStyle = .bezier(width: 2, color: .black)
                
                lineChartView.chartModel.topAxisLineStyle = .none
                lineChartView.chartModel.rightAxisLineStyle = .none
                lineChartView.chartModel.leftAxisLineStyle = .none
                lineChartView.chartModel.bottomAxisLineStyle = .dashLine(width: 1, color: UIColor(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1.0), lengths: [6,3])
                
                lineChartView.chartModel.bottomAxisLabelStyel =  .bottom(color: UIColor(red: 102/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1.0), font: .systemFont(ofSize: 11),offset: 4)
                lineChartView.chartModel.rightAxisLabelStyel = .left(color: UIColor(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1.0), font: .systemFont(ofSize: 11), offset: 0)
                
                lineChartView.chartModel.rightAxisMaxMinStyel = .none
                
                lineChartView.chartModel.rightAxisDataMaxMinStyel = .left(color: UIColor(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1.0), font: .systemFont(ofSize: 11), offset: 0)
                
                lineChartView.chartModel.bottomAxisMaxMinStyel = .bottom(color: UIColor(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1.0), font: .systemFont(ofSize: 11), offset: 0)
                
                lineChartView.chartModel.horizontalLines = [.init(y: 60, lineStyle: .dashLine(width: 1, color: UIColor(red: 192/255.0, green: 2/255.0, blue: 12/255.0, alpha: 1.0), lengths: [4,2]),lableStyle: .left(color: UIColor(red: 192/255.0, green: 2/255.0, blue: 12/255.0, alpha: 1.0), font: .systemFont(ofSize: 11), offset: 0)),.init(y: 20, lineStyle: .dashLine(width: 1, color: UIColor(red: 65/255.0, green: 166/255.0, blue: 89/255.0, alpha: 1.0), lengths: [4,2]),lableStyle: .left(color: UIColor(red: 65/255.0, green: 166/255.0, blue: 89/255.0, alpha: 1.0), font: .systemFont(ofSize: 11), offset: 0))]
                //竖向线段颜色配置
                lineChartView.chartModel.verticalColorRnages = [.init(showType: .line, top: 100, bottom: 60, color: UIColor(red: 192/255.0, green: 2/255.0, blue: 12/255.0, alpha: 1.0)),
                                                                .init(showType: .line, top: 60, bottom: 20, color: UIColor(red: 250/255.0, green: 194/255.0, blue: 12/255.0, alpha: 1.0)),
                                                                .init(showType: .line, top: 20, bottom: 0, color: UIColor(red: 65/255.0, green: 166/255.0, blue: 89/255.0, alpha: 1.0))]
                
                
                lineChartView.chartModel.horizontalAxisFullFrame = true
                //垂直坐标轴是否全屏显示
                lineChartView.chartModel.verticalAxisFullFrame = false
                //是否显示刻度尺
                lineChartView.chartModel.showGraduation = false
                lineChartView.chartModel.XRangeType = .unlimited

                lineChartView.setNeedsDisplay()
            case 1:
                lineChartView.chartModel.chartContentInsert = .init(top: 0, left: 40, bottom: 40, right: 0)
                lineChartView.chartModel.yRangeType = .selfAdaptVisibleWithMinMax(min: 0, max: 60)
                
                lineChartView.chartModel.lineModel.datalineStyle = .bezier(width: 2, color: .black)
                
                lineChartView.chartModel.topAxisLineStyle = .none
                lineChartView.chartModel.rightAxisLineStyle = .none
                lineChartView.chartModel.leftAxisLineStyle = .none
                lineChartView.chartModel.bottomAxisLineStyle = .dashLine(width: 1, color: UIColor(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1.0), lengths: [6,3])
                
                lineChartView.chartModel.bottomAxisLabelStyel =  .bottom(color: UIColor(red: 102/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1.0), font: .systemFont(ofSize: 11),offset: 4)
                lineChartView.chartModel.rightAxisLabelStyel = .left(color: UIColor(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1.0), font: .systemFont(ofSize: 11), offset: 0)
                
                lineChartView.chartModel.rightAxisMaxMinStyel = .none
                
                lineChartView.chartModel.rightAxisDataMaxMinStyel = .left(color: UIColor(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1.0), font: .systemFont(ofSize: 11), offset: 0)
                
                lineChartView.chartModel.horizontalLines = [.init(y: 60, lineStyle: .dashLine(width: 1, color: UIColor(red: 192/255.0, green: 2/255.0, blue: 12/255.0, alpha: 1.0), lengths: [4,2]),lableStyle: .left(color: UIColor(red: 192/255.0, green: 2/255.0, blue: 12/255.0, alpha: 1.0), font: .systemFont(ofSize: 11), offset: 0)),.init(y: 20, lineStyle: .dashLine(width: 1, color: UIColor(red: 65/255.0, green: 166/255.0, blue: 89/255.0, alpha: 1.0), lengths: [4,2]),lableStyle: .left(color: UIColor(red: 65/255.0, green: 166/255.0, blue: 89/255.0, alpha: 1.0), font: .systemFont(ofSize: 11), offset: 0))]
                //竖向线段颜色配置
                lineChartView.chartModel.verticalColorRnages = [.init(showType: .line, top: 100, bottom: 60, color: UIColor(red: 192/255.0, green: 2/255.0, blue: 12/255.0, alpha: 1.0)),
                                                                .init(showType: .line, top: 60, bottom: 20, color: UIColor(red: 250/255.0, green: 194/255.0, blue: 12/255.0, alpha: 1.0)),
                                                                .init(showType: .line, top: 20, bottom: 0, color: UIColor(red: 65/255.0, green: 166/255.0, blue: 89/255.0, alpha: 1.0))]
                
                
                lineChartView.chartModel.horizontalAxisFullFrame = true
                //垂直坐标轴是否全屏显示
                lineChartView.chartModel.verticalAxisFullFrame = false
                //是否显示刻度尺
                lineChartView.chartModel.showGraduation = false
                lineChartView.chartModel.XRangeType = .limitedByData

                lineChartView.setNeedsDisplay()
            case 2:
                lineChartView.chartModel.chartContentInsert = .init(top: 0, left: 40, bottom: 40, right: 0)
                lineChartView.chartModel.yRangeType = .selfAdaptVisibleWithMinMax(min: 0, max: 60)
                
                lineChartView.chartModel.lineModel.datalineStyle = .bezier(width: 2, color: .black)
                
                lineChartView.chartModel.topAxisLineStyle = .none
                lineChartView.chartModel.rightAxisLineStyle = .none
                lineChartView.chartModel.leftAxisLineStyle = .none
                lineChartView.chartModel.bottomAxisLineStyle = .dashLine(width: 1, color: UIColor(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1.0), lengths: [6,3])
                
                lineChartView.chartModel.bottomAxisLabelStyel =  .bottom(color: UIColor(red: 102/255.0, green: 102/255.0, blue: 102/255.0, alpha: 1.0), font: .systemFont(ofSize: 11),offset: 4)
                lineChartView.chartModel.rightAxisLabelStyel = .left(color: UIColor(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1.0), font: .systemFont(ofSize: 11), offset: 0)
                
                lineChartView.chartModel.rightAxisMaxMinStyel = .none
                
                lineChartView.chartModel.rightAxisDataMaxMinStyel = .left(color: UIColor(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1.0), font: .systemFont(ofSize: 11), offset: 0)
                
                lineChartView.chartModel.horizontalLines = [.init(y: 60, lineStyle: .dashLine(width: 1, color: UIColor(red: 192/255.0, green: 2/255.0, blue: 12/255.0, alpha: 1.0), lengths: [4,2]),lableStyle: .left(color: UIColor(red: 192/255.0, green: 2/255.0, blue: 12/255.0, alpha: 1.0), font: .systemFont(ofSize: 11), offset: 0)),.init(y: 20, lineStyle: .dashLine(width: 1, color: UIColor(red: 65/255.0, green: 166/255.0, blue: 89/255.0, alpha: 1.0), lengths: [4,2]),lableStyle: .left(color: UIColor(red: 65/255.0, green: 166/255.0, blue: 89/255.0, alpha: 1.0), font: .systemFont(ofSize: 11), offset: 0))]
                //竖向线段颜色配置
                lineChartView.chartModel.verticalColorRnages = [.init(showType: .line, top: 100, bottom: 60, color: UIColor(red: 192/255.0, green: 2/255.0, blue: 12/255.0, alpha: 1.0)),
                                                                .init(showType: .line, top: 60, bottom: 20, color: UIColor(red: 250/255.0, green: 194/255.0, blue: 12/255.0, alpha: 1.0)),
                                                                .init(showType: .line, top: 20, bottom: 0, color: UIColor(red: 65/255.0, green: 166/255.0, blue: 89/255.0, alpha: 1.0))]
                
                
                lineChartView.chartModel.horizontalAxisFullFrame = true
                //垂直坐标轴是否全屏显示
                lineChartView.chartModel.verticalAxisFullFrame = false
                //是否显示刻度尺
                lineChartView.chartModel.showGraduation = false
                lineChartView.chartModel.XRangeType = .distaceByNow(3600*24*365)

                lineChartView.setNeedsDisplay()
            default:break
            }
        }
    }
    
    func lineChartViewDateModeChanged(mode: DateMode) {
        switch mode {
        case .hour:
            segmentView.selectIndex(index: 0, withDelegate: false)
        case .day:
            segmentView.selectIndex(index: 1, withDelegate: false)

        case .week:
            segmentView.selectIndex(index: 2, withDelegate: false)

        case .month:
            segmentView.selectIndex(index: 3, withDelegate: false)

        case .year:
            segmentView.selectIndex(index: 4, withDelegate: false)

        }
    }
    
    
    func lineChartViewXRangeChanged(min: Double, max: Double) {
        let mindate = Date.init(timeIntervalSince1970: min)
        let maxdate = Date.init(timeIntervalSince1970: max)
        minDatePicker.date  = mindate
        maxDatePicker.date = maxdate
    }
    
    func lineChartViewHLineFormatStr(y: Double) -> String {
        let str = "\(y)"
        return str
    }
    
//    func lineChartViewHLineFormatAttributeStr(y: Double) -> NSAttributedString {
////        let str = "Max\n\(y)℃"
////        let paragraphStyle = NSMutableParagraphStyle()
////               paragraphStyle.alignment = .center
////        let attrStr = NSMutableAttributedString.init(string: str)
////        attrStr.addAttributes([.foregroundColor:UIColor.red,.font:UIFont.systemFont(ofSize: 14),.paragraphStyle:paragraphStyle], range: NSRange.init(location: 0, length: 3))
////        return attrStr
//        let str = "\(y)"
//        let paragraphStyle = NSMutableParagraphStyle()
//               paragraphStyle.alignment = .center
//        let attrStr = NSMutableAttributedString.init(string: str)
//        return attrStr
//    }

    
    func lineChartViewTapedItemFormatStrs(x: Double, y: Double) -> [String] {
        let date = Date.init(timeIntervalSince1970: x).toString(format: "yyyy/MM/dd HH:mm:ss")
        return ["\(y)℃","\(date)"]
    }
}

