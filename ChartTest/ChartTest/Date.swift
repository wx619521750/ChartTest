//
//  Date.swift
//  AIoT
//
//  Created by 王星鑫 on 2022/9/23.
//

import Foundation

public extension Date {
    static let secsInMin: TimeInterval = 60
    static let minsInHour: TimeInterval = 60
    static let hoursInDay: TimeInterval = 24
    static let daysInWeek: TimeInterval = 7
    func toString(format: String = "yyyy-MM-dd") -> String {
        let formater = DateFormatter()

        formater.dateFormat = format

        return formater.string(from: self)
    }
    
    static func dateFromString(str:String,format:String = "yyyy-MM-dd") -> Date?{
        let formater = DateFormatter()

        formater.dateFormat = format

        return formater.date(from: str)
    }

    func toGMT() -> Date {
        let currentTiemZome = NSTimeZone.local
        let secondsDistance = currentTiemZome.secondsFromGMT()
        return Date.init(timeInterval: TimeInterval(-secondsDistance), since: self)
    }
    func toLocal() -> Date {
        let currentTiemZome = NSTimeZone.local
        let secondsDistance = currentTiemZome.secondsFromGMT()
        return Date.init(timeInterval: TimeInterval(+secondsDistance), since: self)
    }

    // 当前日期加一天

    static func dateSinceNow(days: TimeInterval) -> Date {
        let timeInterval = Date.timeIntervalSinceReferenceDate+secsInMin*minsInHour*hoursInDay*days
        return Date.init(timeIntervalSinceReferenceDate: timeInterval)
    }

    static func dateSinceNow(hours: TimeInterval) -> Date {
        let timeInterval = Date.timeIntervalSinceReferenceDate+secsInMin*minsInHour*hours
        return Date.init(timeIntervalSinceReferenceDate: timeInterval)
    }

    static func dateSinceNow(mins: TimeInterval) -> Date {
        let timeInterval = Date.timeIntervalSinceReferenceDate+secsInMin*minsInHour*mins
        return Date.init(timeIntervalSinceReferenceDate: timeInterval)
    }

    static func tomorrow() -> Date {
        return dateSinceNow(days: 1)

    }

    static func yestoday() -> Date {
        return dateSinceNow(days: -1)
    }

    func dateIgnoringTime() -> Date? {
        let calendar = Calendar.current
        let unitFlag: Set<Calendar.Component> = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day]
        let componentsSelf = calendar.dateComponents(unitFlag, from: self)
        return calendar.date(from: componentsSelf)
    }
    func dateIgnoringMin() -> Date? {
        let calendar = Calendar.current
        let unitFlag: Set<Calendar.Component> = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day,Calendar.Component.hour]
        let componentsSelf = calendar.dateComponents(unitFlag, from: self)
        return calendar.date(from: componentsSelf)
    }

    // conpare

    func isEqualToDateIgnoringTime(date: Date) -> Bool {
        let calendar = Calendar.current
        let unitFlag: Set<Calendar.Component> = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day]
        let componentsSelf = calendar.dateComponents(unitFlag, from: self)
        let componentsDate = calendar.dateComponents(unitFlag, from: date)
        if componentsSelf.year == componentsDate.year && componentsSelf.month == componentsDate.month && componentsSelf.day == componentsDate.day {
            return true
        }
        return false
    }

    func isToday() -> Bool {
       return self.isEqualToDateIgnoringTime(date: Date())
    }

    func isTomorrow() -> Bool {
        return self.isEqualToDateIgnoringTime(date: Date.tomorrow())
    }

    func isYestoday() -> Bool {
        return self.isEqualToDateIgnoringTime(date: Date.yestoday())
    }

    func isSameWeekAsDate(date: Date) -> Bool {
        let calendar = Calendar.current
        let unitFlag: Set<Calendar.Component> = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day]
        let componentsSelf = calendar.dateComponents(unitFlag, from: self)
        let componentsDate = calendar.dateComponents(unitFlag, from: date)
        if componentsDate.year == componentsSelf.year && componentsSelf.weekOfYear == componentsDate.weekOfYear {
            return true
        }
        return false
    }

    func isThisWeek() -> Bool {
        return self.isSameWeekAsDate(date: Date())
    }

    func isNextWeek() -> Bool {
        return self.isSameWeekAsDate(date: Date.dateSinceNow(days: Date.daysInWeek))
    }

    func isLastWeek() -> Bool {
        return self.isSameWeekAsDate(date: Date.dateSinceNow(days: -Date.daysInWeek))
    }

    func isSameMonthAsDate(date: Date) -> Bool {
        let calendar = Calendar.current
        let unitFlag: Set<Calendar.Component> = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day]
        let componentsSelf = calendar.dateComponents(unitFlag, from: self)
        let componentsDate = calendar.dateComponents(unitFlag, from: date)
        if componentsDate.year == componentsSelf.year && componentsSelf.month == componentsDate.month {
            return true
        }
        return false
    }

    func isThisMonth() -> Bool {
        return self.isSameMonthAsDate(date: Date())
    }

    func isSameYearAsDate(date: Date) -> Bool {
        let calendar = Calendar.current
        let unitFlag: Set<Calendar.Component> = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day]
        let componentsSelf = calendar.dateComponents(unitFlag, from: self)
        let componentsDate = calendar.dateComponents(unitFlag, from: date)
        if componentsDate.year == componentsSelf.year {
            return true
        }
        return false
    }

    func isThisYear() -> Bool {
        return self.isSameYearAsDate(date: Date())
    }

    func isNextYear() -> Bool {
        let calendar = Calendar.current
        let unitFlag: Set<Calendar.Component> = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day]
        let componentsSelf = calendar.dateComponents(unitFlag, from: self)
        let componentsDate = calendar.dateComponents(unitFlag, from: Date())
        if componentsDate.year == componentsSelf.year!-1 {
            return true
        }
        return false

    }

    func isLastYear() -> Bool {
        let calendar = Calendar.current
        let unitFlag: Set<Calendar.Component> = [Calendar.Component.year, Calendar.Component.month, Calendar.Component.day]
        let componentsSelf = calendar.dateComponents(unitFlag, from: self)
        let componentsDate = calendar.dateComponents(unitFlag, from: Date())
        if componentsDate.year == componentsSelf.year!+1 {
            return true
        }
        return false
    }

    func dateByAddingDays(days: NSInteger) -> Date? {
        var dateComponent = DateComponents.init()
        dateComponent.day = days
        return Calendar.current.date(byAdding: dateComponent, to: self)
    }

    func dateByAddingMonths(months: NSInteger) -> Date? {
        var dateComponent = DateComponents.init()
        dateComponent.month = months
        return Calendar.current.date(byAdding: dateComponent, to: self)
    }

    func dateByAddingYears(years: NSInteger) -> Date? {
        var dateComponent = DateComponents.init()
        dateComponent.year = years
        return Calendar.current.date(byAdding: dateComponent, to: self)
    }

    func isWeekend() -> Bool {
        let range = Calendar.current.maximumRange(of: Calendar.Component.weekday)
        let weekday = Calendar.current.component(.weekday, from: self)
        if weekday == range?.lowerBound || weekday == range?.upperBound {
            return true
        }
        return false
    }

    // 本月开始日期
    func startOfCurrentMonth() -> Date {
        let date = Date()
        let calendar = NSCalendar.current
        let components = calendar.dateComponents(
            Set<Calendar.Component>([.year, .month]), from: date)
        let startOfMonth = calendar.date(from: components)!
        return startOfMonth
    }

    // 本月结束日期
    func endOfCurrentMonth(returnEndTime: Bool = false) -> Date {
        let calendar = NSCalendar.current
        var components = DateComponents()
        components.month = 1
        if returnEndTime {
            components.second = -1
        } else {
            components.day = -1
        }

        let endOfMonth =  calendar.date(byAdding: components, to: startOfCurrentMonth())!
        return endOfMonth
    }

    var year: Int {
        return Calendar.current.component(Calendar.Component.year, from: self)
    }
    var month: Int {
        return Calendar.current.component(Calendar.Component.month, from: self)
    }
    var day: Int {
        return Calendar.current.component(Calendar.Component.day, from: self)
    }
    var hour: Int {
        return Calendar.current.component(Calendar.Component.hour, from: self)
    }
    var minute: Int {
        return Calendar.current.component(Calendar.Component.minute, from: self)
    }
    var second: Int {
        return Calendar.current.component(Calendar.Component.second, from: self)
    }

    var weekOfYear: Int {
        return Calendar.current.component(Calendar.Component.weekOfYear, from: self)
    }

    var weekOfMonth: Int {
        return Calendar.current.component(Calendar.Component.weekOfMonth, from: self)
    }

    var weekDay: Int {
        return Calendar.current.component(Calendar.Component.weekday, from: self)
    }
}
