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
        initDataOCRadar()
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
        segmentView1.selectIndex(index: 0, withDelegate: false)
    }
    
    func initDataOCRadar(){
        
        
        var points = [ChartPoint]()
        if let data = loadData() {
            var x:Double = 0
            var y:Double = 0
            for (key,value) in data{
                for str in value{
                    let strs = str.components(separatedBy: ",")
                    let dateStr = key+strs[0]
                    x = Date.dateFromString(str: dateStr, format: "yyyyMMddHHmmss")?.timeIntervalSince1970 ?? 0
                    y = Double(strs[1]) ?? 0
                    let item = ChartPoint()
                    item.x = x
                    item.y = y
                    points.append(item)
                }
            }
        }
        let model = ChartModel.init(points: points, type: .radon)

        lineChartView.chartModel = model
        segmentView1.selectIndex(index: 0, withDelegate: false)
    }
    
    func initDataOCTemp(){
        
        
        var points = [ChartPoint]()
        if let data = loadData() {
            var x:Double = 0
            var y:Double = 0
            for (key,value) in data{
                for str in value{
                    let strs = str.components(separatedBy: ",")
                    let dateStr = key+strs[0]
                    x = Date.dateFromString(str: dateStr, format: "yyyyMMddHHmmss")?.timeIntervalSince1970 ?? 0
                    y = Double(strs[1]) ?? 0
                    let item = ChartPoint()
                    item.x = x
                    item.y = y
                    points.append(item)
                }
            }
        }
        let model = ChartModel.init(points: points, type: .temperature)

        lineChartView.chartModel = model
        segmentView1.selectIndex(index: 1, withDelegate: false)
    }
    
    func initDataOCHum(){
        
        
        var points = [ChartPoint]()
        if let data = loadData() {
            var x:Double = 0
            var y:Double = 0
            for (key,value) in data{
                for str in value{
                    let strs = str.components(separatedBy: ",")
                    let dateStr = key+strs[0]
                    x = Date.dateFromString(str: dateStr, format: "yyyyMMddHHmmss")?.timeIntervalSince1970 ?? 0
                    y = Double(strs[1]) ?? 0
                    let item = ChartPoint()
                    item.x = x
                    item.y = y
                    points.append(item)
                }
            }
        }
        let model = ChartModel.init(points: points, type: .humidity)

        lineChartView.chartModel = model
        segmentView1.selectIndex(index: 2, withDelegate: false)
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
        view.titles = ["day","week","month","year"]
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
                lineChartView.changeDateMode(mode: .day)
            case 1:
                lineChartView.changeDateMode(mode: .week)
            case 2:
                lineChartView.changeDateMode(mode: .month)
            case 3:
                lineChartView.changeDateMode(mode: .year)
            default:break
                
            }
        }else{
            
            switch selectedIndex{
            case 0:
                initDataOCRadar()
            case 1:
                initDataOCTemp()
            case 2:
                initDataOCHum()
            default:break
            }
        }
    }
    
    func lineChartViewDateModeChanged(chartView: LineChartView, mode: DateMode) {
        switch mode {
        case .hour:
            segmentView.selectIndex(index: 0, withDelegate: false)
        case .day:
            segmentView.selectIndex(index: 0, withDelegate: false)

        case .week:
            segmentView.selectIndex(index: 1, withDelegate: false)

        case .month:
            segmentView.selectIndex(index: 2, withDelegate: false)

        case .year:
            segmentView.selectIndex(index: 3, withDelegate: false)

        }
    }
    
    
    func lineChartViewXRangeChanged(chartView: LineChartView, min: Double, max: Double) {
        let mindate = Date.init(timeIntervalSince1970: min)
        let maxdate = Date.init(timeIntervalSince1970: max)
        minDatePicker.date  = mindate
        maxDatePicker.date = maxdate
    }
    
    func lineChartViewHLineFormatAttributeStr(chartView: LineChartView, y: Double) -> NSAttributedString {
        return NSAttributedString(string: "\(y)", attributes: [
            .foregroundColor: UIColor.red,
            .font: UIFont.systemFont(ofSize: 18)
        ])
    }


    func lineChartViewTapedItemFormatStrs(chartView: LineChartView, x: Double, y: Double) -> XYAttrModel {
        let date = Date.init(timeIntervalSince1970: x).toString(format: "yyyy/MM/dd HH:mm")
        return XYAttrModel(
            xAttr: NSAttributedString(string: date, attributes: [.font:UIFont.systemFont(ofSize: 18), .foregroundColor:UIColor.red]),
            yAttr: NSAttributedString(string: "\(y)℃", attributes: [.font:UIFont.boldSystemFont(ofSize: 18), .foregroundColor:UIColor.red])
        )
    }


    func lineChartViewRightAxisDataMaxMinFormatStr(chartView: LineChartView, min: Double, max: Double) -> MaxMinAttrModel {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.red
        ]
        return MaxMinAttrModel(
            max: NSAttributedString(string: "Max:\(floor(max))", attributes: attributes),
            min: NSAttributedString(string: "Min:\(floor(min))", attributes: attributes)
        )
    }

    func lineChartViewAxisGraduationFormatStr(chartView: LineChartView, direction: AxisDirection, value: Double) -> NSAttributedString? {
        switch direction {
        case .top:
            break
        case .bottom:

            let date = Date.init(timeIntervalSince1970: value)
            let str = date.toString(format: "yyyy")
            return NSAttributedString(string: str, attributes: [.foregroundColor:UIColor.red, .font:UIFont.systemFont(ofSize: 18)])
        case .left:
            break
        case .right:
            return NSAttributedString(string: String(format: "%.1f", value), attributes: [.foregroundColor:UIColor.red, .font:UIFont.systemFont(ofSize: 18)])
        }
        return nil
    }

    func lineChartViewBottomAxisMaxMinFormatStr(chartView: LineChartView, x: Double) -> NSAttributedString {
        let date = Date.init(timeIntervalSince1970: x).toString(format: "yyyy/MM/dd HH:mm")
        return NSAttributedString(string: date, attributes: [.font:UIFont.systemFont(ofSize: 18), .foregroundColor:UIColor.red])
    }
}
