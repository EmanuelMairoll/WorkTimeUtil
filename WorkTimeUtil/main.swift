import Foundation

enum WorkTimeUtilCommand {
    case calculate(parameters: [String])
    case push(parameters: [String])
    case config(key: String?, value: String?)
}

private func parseCommand(_ args: [String]) -> WorkTimeUtilCommand? {
    let binaryName = URL(fileURLWithPath: args.first ?? "").lastPathComponent

    if binaryName == "wtc" {
        return .calculate(parameters: Array(args.dropFirst()))
    } else if binaryName == "wtp" {
        return .push(parameters: Array(args.dropFirst()))
    }

    if args.count < 2 {
        return nil
    }

    let subcommand = args[1]

    switch subcommand {
    case "calculate":
        let parameters = Array(args.dropFirst(2))
        return .calculate(parameters: parameters)
    case "push":
        let parameters = Array(args.dropFirst(2))
        return .push(parameters: parameters)
    case "config":
        let key = args.count > 2 ? args[2] : nil
        let value = args.count > 3 ? args[3] : nil
        return .config(key: key, value: value)
    default:
        return nil
    }
}

public func parseDateParameter(_ command: String) -> (startDate: Date, endDate: Date)? {
    switch command {
    case "W":
        return CalUtil.startAndEndDatesForCurrentWeek()
    case let weekArg where weekArg.starts(with: "W"):
        let parts = weekArg.split(separator: "/")
        let week = Int(parts[0].dropFirst()) ?? 0
        let year = parts.count > 1 ? Int(parts[1]) ?? 0 : nil
        return CalUtil.startAndEndDatesForWeek(week: week, year: year)
    case "M":
        return CalUtil.startAndEndDatesForCurrentMonth()
    case let monthArg where monthArg.starts(with: "M"):
        let parts = monthArg.split(separator: "/")
        let month = Int(parts[0].dropFirst()) ?? 0
        let year = parts.count > 1 ? Int(parts[1]) ?? 0 : nil
        return CalUtil.startAndEndDatesForMonth(month: month, year: year)
    default:
        return nil
    }
}

func main() async {
    let calendarManager = CalendarManager()
    let apiKey = getAbsenceIOCreds()?.split(separator: ":")
    let absenceAPI = apiKey != nil ? AbsenceAPI(id: String(apiKey![0]), key: String(apiKey![1])) : nil

    guard await calendarManager.requestAccess() else {
        print("Access to the calendar is denied.")
        exit(1)
    }

    guard let command = parseCommand(CommandLine.arguments) else {
        print("""
            Invalid command. Usage:
            worktimeutil calculate [W|W<n>[/<yy>]|M|M<n>[/<yy>]]
            worktimeutil push [W|W<n>[/<yy>]|M|M<n>[/<yy>]]
            worktimeutil config [key] [value]
            """)
        exit(1)
    }

    switch command {
    case let .calculate(parameters):
        calculateWorkHours(parameters, calendar: calendarManager)
    case let .push(parameters):
        guard let absenceAPI else {
            print("No API creds set. Set via: worktimeutil config absenceIOCreds <ID>:<KEY>")
            exit(1)
        }
        await pushToAbsence(parameters, calendar: calendarManager, absenceAPI: absenceAPI)
    case let .config(key, value):
        config(key: key, value: value)
    }

    exit(0)
}

extension Double {
    func rounded(toDecimalPlaces places: Int) -> Double {
        let multiplier = pow(10, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}

Task {
    await main()
}

RunLoop.main.run()
