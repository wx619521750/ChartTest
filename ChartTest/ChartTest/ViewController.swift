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
        scrollView.addSubview(radonChartView)
        scrollView.addSubview(temperatureChartView)
        scrollView.addSubview(humidityChartView)
        scrollView.addSubview(segmentView)
        scrollView.addSubview(minDatePicker)
        scrollView.addSubview(maxDatePicker)
        scrollView.addSubview(binaryTimelineChartView)
        initChartData()
        initBinaryTimelineData()
    }

    func initChartData() {
        let points = loadChartPoints()
        radonChartView.chartModel = ChartModel(points: points, type: .radon)
        temperatureChartView.chartModel = ChartModel(points: points, type: .temperature)
        humidityChartView.chartModel = ChartModel(points: points, type: .humidity)
        syncVisibleRange(
            min: radonChartView.chartModel.minX,
            max: radonChartView.chartModel.maxX,
            source: radonChartView
        )
    }

    private func initBinaryTimelineData() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        func timestamp(hour: Int, minute: Int) -> TimeInterval {
            Calendar.current.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: startOfDay
            )?.timeIntervalSince1970 ?? startOfDay.timeIntervalSince1970
        }

        binaryTimelineChartView.chartModel = BinaryTimelineChartModel(points: [
            BinaryTimelinePointModel(x: timestamp(hour: 0, minute: 0), y: 0),
//            BinaryTimelinePointModel(x: timestamp(hour: 1, minute: 0), y: 0),
//            BinaryTimelinePointModel(x: timestamp(hour: 2, minute: 0), y: 0),
            BinaryTimelinePointModel(x: timestamp(hour: 3, minute: 0), y: 0),
            BinaryTimelinePointModel(x: timestamp(hour: 4, minute: 0), y: 1),
            BinaryTimelinePointModel(x: timestamp(hour: 5, minute: 0), y: 1),
            BinaryTimelinePointModel(x: timestamp(hour: 6, minute: 0), y: 1),
            BinaryTimelinePointModel(x: timestamp(hour: 7, minute: 0), y: 0),
            BinaryTimelinePointModel(x: timestamp(hour: 8, minute: 0), y: 1),
            BinaryTimelinePointModel(x: timestamp(hour: 8, minute: 1), y: 0),
            BinaryTimelinePointModel(x: timestamp(hour: 9, minute: 0), y: 0),
            BinaryTimelinePointModel(x: timestamp(hour: 13, minute: 46), y: 1),
            BinaryTimelinePointModel(x: timestamp(hour: 14, minute: 46), y: 1),
            BinaryTimelinePointModel(x: timestamp(hour: 15, minute: 39), y: 0),
            BinaryTimelinePointModel(x: timestamp(hour: 16, minute: 5), y: 1),
            BinaryTimelinePointModel(x: timestamp(hour: 16, minute: 25), y: 0),
            BinaryTimelinePointModel(x: timestamp(hour: 18, minute: 40), y: 1),
            BinaryTimelinePointModel(x: timestamp(hour: 20, minute: 55), y: 0),
            BinaryTimelinePointModel(x: Date().dateIgnoringTime()?.dateByAddingDays(days: 1)?.timeIntervalSince1970 ?? 0, y: 0)

        ])
    }

    func loadChartPoints() -> [ChartPoint] {
        var points = [ChartPoint]()
        if let data = loadData() {
            for (key,value) in data{
                for str in value{
                    let strs = str.components(separatedBy: ",")
                    guard strs.count >= 2 else { continue }
                    let dateStr = key+strs[0]
                    let x = Date.dateFromString(str: dateStr, format: "yyyyMMddHHmmss")?.timeIntervalSince1970 ?? 0
                    let y = Double(strs[1]) ?? 0
                    let item = ChartPoint()
                    item.x = x
                    item.y = y
                    points.append(item)
                }
            }
        }
        return points
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

    
    private func makeChartView(y: CGFloat) -> LineChartView {
        let view = LineChartView()
        view.frame = .init(x: 20, y: y, width: UIScreen.main.bounds.width-40, height: 240)
        view.backgroundColor = .white
        view.delegate = self
        return view
    }

    lazy var radonChartView = makeChartView(y: 20)
    lazy var temperatureChartView = makeChartView(y: 280)
    lazy var humidityChartView = makeChartView(y: 540)

    private var chartViews: [LineChartView] {
        [radonChartView, temperatureChartView, humidityChartView]
    }
    
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.contentSize = .init(width: UIScreen.main.bounds.width, height: 1200)
        view.frame = .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        return view
    }()
    
    lazy var segmentView: SegmentView = {
        let view = SegmentView.init(frame: .init(x: 20, y: 800, width: UIScreen.main.bounds.width-40, height: 44))
        view.titles = ["day","week","month","year"]
        view.tag = 101

        view.delegate = self
        return view
    }()
    
    lazy var minDatePicker: UIDatePicker = {
        let view = UIDatePicker()
        view.frame = .init(x: 20, y: 844, width: UIScreen.main.bounds.width-40, height: 44)
        view.datePickerMode = .dateAndTime
        view.addTarget(self,
                            action: #selector(dateChanged(_:)),
                            for: .valueChanged)
        return view
    }()
    lazy var maxDatePicker: UIDatePicker = {
        let view = UIDatePicker()
        view.frame = .init(x: 20, y: 888, width: UIScreen.main.bounds.width-40, height: 44)
        view.datePickerMode = .dateAndTime
        view.addTarget(self,
                            action: #selector(dateChanged(_:)),
                            for: .valueChanged)
        return view
    }()

    lazy var binaryTimelineChartView: BinaryTimelineChartView = {
        let view = BinaryTimelineChartView(
            frame: CGRect(x: 20, y: 952, width: UIScreen.main.bounds.width - 40, height: 220)
        )
        return view
    }()
    
    @objc func dateChanged(_ sender: UIDatePicker) {
        let selectedDate = sender.date
        print("选择的日期: \(selectedDate)")

        syncVisibleRange(
            min: minDatePicker.date.timeIntervalSince1970,
            max: maxDatePicker.date.timeIntervalSince1970,
            source: nil
        )
    }
    
    func segmentView(_ segmentView: SegmentView, selectedIndex: Int) {
        let mode: DateMode
        switch selectedIndex {
        case 0: mode = .day
        case 1: mode = .week
        case 2: mode = .month
        case 3: mode = .year
        default: return
        }
        radonChartView.changeDateMode(mode: mode)
        syncVisibleRange(
            min: radonChartView.chartModel.minX,
            max: radonChartView.chartModel.maxX,
            source: radonChartView
        )
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
        minDatePicker.date = Date(timeIntervalSince1970: min)
        maxDatePicker.date = Date(timeIntervalSince1970: max)
    }

    func lineChartViewXRangeChangedByUserInteraction(chartView: LineChartView, min: Double, max: Double) {
        syncVisibleRange(min: min, max: max, source: chartView)
    }

    private func syncVisibleRange(min: Double, max: Double, source: LineChartView?) {
        guard min < max else { return }

        minDatePicker.date = Date(timeIntervalSince1970: min)
        maxDatePicker.date = Date(timeIntervalSince1970: max)
        for chartView in chartViews where chartView !== source {
            chartView.changeXRange(min: min, max: max)
        }
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
