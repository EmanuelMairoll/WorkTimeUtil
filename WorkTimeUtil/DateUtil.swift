import Foundation

class CalUtil {
    static func startAndEndDatesForCurrentWeek() -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        return (startOfWeek, endOfWeek)
    }

    static func startAndEndDatesForWeek(week: Int, year: Int?) -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()
        var currentYear = calendar.component(.year, from: now)

        if let year = year {
            if year < 100 {
                currentYear = currentYear - (currentYear % 100) + year
            } else {
                currentYear = year
            }
        }

        let weekRange = calendar.range(of: .weekOfYear, in: .year, for: now)!
        let maxWeek = weekRange.upperBound - 1
        let adjustedWeek = week > maxWeek ? maxWeek : week
        let startOfWeek = calendar.date(from: DateComponents(weekOfYear: adjustedWeek, yearForWeekOfYear: currentYear))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        return (startOfWeek, endOfWeek)
    }

    static func startAndEndDatesForCurrentMonth() -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        return (startOfMonth, endOfMonth)
    }

    static func startAndEndDatesForMonth(month: Int, year: Int?) -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let now = Date()

        var currentYear = calendar.component(.year, from: now)

        if let year = year {
            if year < 100 {
                currentYear = currentYear - (currentYear % 100) + year
            } else {
                currentYear = year
            }
        }

        let maxMonth = calendar.monthSymbols.count
        let adjustedMonth = month > maxMonth ? maxMonth : month
        let startOfMonth = calendar.date(from: DateComponents(year: currentYear, month: adjustedMonth))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        return (startOfMonth, endOfMonth)
    }

    static func isWeekend(date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: date)
        guard let weekday = components.weekday else {
            return false
        }

        // Sunday is 1 and Saturday is 7 in the Gregorian calendar
        return weekday == 1 || weekday == 7
    }

    static func calculateActualWorkHours(startDate: Date, endDate: Date, workEvents: [WorkEvent]) -> TimeInterval {
        var totalDuration: TimeInterval = 0
        for workEvent in workEvents.filter({ $0.isWork }) {
            let duration = workEvent.endDate.timeIntervalSince(workEvent.startDate)
            totalDuration += duration
        }

        return totalDuration / 3600
    }

    static func calculateTargetWorkHours(startDate: Date, endDate: Date, workEvents: [WorkEvent]) -> TimeInterval {
        let workHoursPerWeek: TimeInterval = 22.0

        var totalDuration: TimeInterval = 0
        var currentDate = startDate

        while currentDate <= endDate {
            // Check if current date is a weekend or holiday
            let calendar = Calendar.current
            let dayOfWeek = calendar.component(.weekday, from: currentDate)
            if dayOfWeek == 1 || dayOfWeek == 7 {
                // Weekend
            } else {
                // Work day
                let matchingEvents = workEvents.filter { $0.startDate <= currentDate && $0.endDate > currentDate }
                let isWorkDay = matchingEvents.isEmpty || matchingEvents.allSatisfy { $0.isWork }
                if isWorkDay {
                    totalDuration += workHoursPerWeek / 5.0
                }
            }

            // Move to the next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return totalDuration
    }
}

extension Date {
    func startOfDay() -> Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: self).convert(to: .gmt) //HACK
    }

    func endOfDay() -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 1, to: startOfDay())!
    }

    func convert(from: TimeZone = .current, to: TimeZone) -> Date {
        let calendar = Calendar.current
        let targetOffset = TimeInterval(from.secondsFromGMT(for: self))
        let localOffset = TimeInterval(to.secondsFromGMT(for: self))

        let totalOffset = targetOffset - localOffset
        return calendar.date(byAdding: .second, value: Int(totalOffset), to: self)!
    }
}

extension JSONDecoder.DateDecodingStrategy {
    static var iso8601ex: JSONDecoder.DateDecodingStrategy {
        let dateFormatter1 = ISO8601DateFormatter()
        dateFormatter1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let dateFormatter2 = ISO8601DateFormatter()

        return .custom { decoder in
            let dateString = try decoder.singleValueContainer().decode(String.self)

            if let date = dateFormatter1.date(from: dateString) {
                return date
            } else if let date = dateFormatter2.date(from: dateString) {
                return date
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid date format"))
            }
        }
    }
}

extension JSONEncoder.DateEncodingStrategy {
    static var iso8601ex: JSONEncoder.DateEncodingStrategy {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return .custom { (date, encoder) throws in
            let dateString = dateFormatter.string(from: date)

            var container = encoder.singleValueContainer()
            try container.encode(dateString)
        }
    }
}
