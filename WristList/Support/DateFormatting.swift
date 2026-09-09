//
//  DateFormatting.swift
//  WristList
//

import Foundation

enum DateFormatting {
    static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return components.date ?? Date(timeIntervalSince1970: 0)
    }

    static func festivalRange(startDate: Date, endDate: Date) -> String {
        let calendar = Calendar.current
        let startMonth = startDate.formatted(.dateTime.month(.abbreviated))
        let startDay = startDate.formatted(.dateTime.day())
        let endDay = endDate.formatted(.dateTime.day())
        let endMonth = endDate.formatted(.dateTime.month(.abbreviated))

        if calendar.component(.month, from: startDate) == calendar.component(.month, from: endDate) {
            return "\(startMonth) \(startDay)-\(endDay)"
        }

        return "\(startMonth) \(startDay)-\(endMonth) \(endDay)"
    }

    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    static func monthYear(_ date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).year())
    }
}
