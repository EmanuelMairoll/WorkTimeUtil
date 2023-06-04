import Foundation

func calculateWorkHours(_ parameters: [String], calendar: CalendarManager) {
    let workHoursPerWeek = getWorkHoursPerWeek() ?? 38.5
    let removeLunchBreak = getRemoveLunchBreak() ?? true

    for parameter in parameters {
        guard let (startDate, endDate) = parseDateParameter(parameter) else {
            print("Invalid command. Usage: worktimeutil calculate [W|W<n>[/<yy>]|M|M<n>[/<yy>]]")
            exit(1)
        }

        let workEvents = calendar.fetchEvents(startDate: startDate, endDate: endDate)
        let shouldWork = calculateTargetWorkHours(startDate: startDate, endDate: endDate, workEvents: workEvents, workHoursPerWeek: workHoursPerWeek)
        let didWork = calculateActualWorkHours(startDate: startDate, endDate: endDate, workEvents: workEvents, removeLunchBreak: removeLunchBreak)

        print("For '\(parameter)':")
        print("Should Work: \(shouldWork.rounded(toDecimalPlaces: 2)) hours")
        print("Did Work: \(didWork.rounded(toDecimalPlaces: 2)) hours")
        print("")
    }
}

private func calculateActualWorkHours(startDate: Date, endDate: Date, workEvents: [WorkEvent], removeLunchBreak: Bool) -> TimeInterval {
    var totalDuration: TimeInterval = 0
    for workEvent in workEvents.filter({ $0.isWork }) {
        let duration = workEvent.endDate.timeIntervalSince(workEvent.startDate)
        totalDuration += duration

        if removeLunchBreak && (workEvent.type == .office || workEvent.type == .homeOffice) && duration > 6 * 3600 {
            totalDuration -= 0.5 * 3600
        }
    }

    return totalDuration / 3600
}


private func calculateTargetWorkHours(startDate: Date, endDate: Date, workEvents: [WorkEvent], workHoursPerWeek: TimeInterval) -> TimeInterval {
    var totalDuration: TimeInterval = 0
    var currentDate = startDate

    while currentDate <= endDate {
        // Check if current date is a weekend or holiday
        let calendar = Calendar.gmt
        let dayOfWeek = calendar.component(.weekday, from: currentDate)
        if dayOfWeek == 1 || dayOfWeek == 7 {
            // Weekend
        } else {
            // Work day
            let matchingEvents = workEvents.filter { $0.startDate <= currentDate && $0.endDate > currentDate }
            let isWorkDay = !matchingEvents.contains { $0.reducesTarget };
            if isWorkDay {
                totalDuration += workHoursPerWeek / 5.0
            }
        }

        // Move to the next day
        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
    }

    return totalDuration
}
