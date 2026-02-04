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
        view.delegate = self
        return view
    }()
    
    lazy var minDatePicker: UIDatePicker = {
        let view = UIDatePicker()
        view.frame = .init(x: 20, y: 384, width: UIScreen.main.bounds.width-40, height: 44)
        view.datePickerMode = .dateAndTime
        view.addTarget(self,
                            action: #selector(dateChanged(_:)),
                            for: .valueChanged)
        return view
    }()
    lazy var maxDatePicker: UIDatePicker = {
        let view = UIDatePicker()
        view.frame = .init(x: 20, y: 428, width: UIScreen.main.bounds.width-40, height: 44)
        view.datePickerMode = .dateAndTime
        view.addTarget(self,
                            action: #selector(dateChanged(_:)),
                            for: .valueChanged)
        return view
    }()
    
    @objc func dateChanged(_ sender: UIDatePicker) {
        let selectedDate = sender.date
        print("选择的日期: \(selectedDate)")

        lineChartView.changeXRange(min: minDatePicker.date.timeIntervalSinceReferenceDate, max:  maxDatePicker.date.timeIntervalSinceReferenceDate)
    }
    
    func segmentView(_ segmentView: SegmentView, selectedIndex: Int) {
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
        let mindate = Date.init(timeIntervalSinceReferenceDate: min)
        let maxdate = Date.init(timeIntervalSinceReferenceDate: max)
        minDatePicker.date  = mindate
        maxDatePicker.date = maxdate
    }

    func lineChartViewHLineFormatStr(y: Double) -> String {
        return "Max\n\(y)℃"
    }
    
    func lineChartViewTapedItemFormatStrs(x: Double, y: Double) -> [String] {
        let date = Date.init(timeIntervalSince1970: x).toString(format: "yyyy/MM/dd HH:mm:ss")
        return ["\(y)℃","\(date)"]
    }
}

