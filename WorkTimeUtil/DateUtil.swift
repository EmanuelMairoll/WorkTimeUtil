import Foundation

class CalUtil {
    static func startAndEndDatesForCurrentWeek() -> (startDate: Date, endDate: Date) {
        let cal = Calendar.gmt
        let now = Date()
        let startOfWeek = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let endOfWeek = cal.date(byAdding: .day, value: 6, to: startOfWeek)!
        return (startOfWeek, endOfWeek)
    }

    static func startAndEndDatesForWeek(week: Int, year: Int?) -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.gmt
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
        let calendar = Calendar.gmt
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        return (startOfMonth, endOfMonth)
    }

    static func startAndEndDatesForMonth(month: Int, year: Int?) -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.gmt
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
        let calendar = Calendar.gmt
        let components = calendar.dateComponents([.weekday], from: date)
        guard let weekday = components.weekday else {
            return false
        }

        // Sunday is 1 and Saturday is 7 in the Gregorian calendar
        return weekday == 1 || weekday == 7
    }
}

extension Calendar {
    static var gmt: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .gmt
        return cal
    }
}

extension Date {
    func cropTime() -> Date {
        let cal = Calendar.gmt
        let components = cal.dateComponents([.year, .month, .day], from: self)
        return cal.date(from: components) ?? self
    }

    func plusOneDay() -> Date {
        return Calendar.gmt.date(byAdding: .day, value: 1, to: self)!
    }

    func cropSeconds() -> Date {
        let cal = Calendar.gmt
        let components = cal.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        return cal.date(from: components) ?? self
    }

    func stripTimezone(_ timezone: TimeZone?) -> Date {
        guard let timezone else {
            return self
        }

        let offset = TimeInterval(timezone.secondsFromGMT(for: self))
        return Calendar.gmt.date(byAdding: .second, value: Int(offset), to: self)!
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
