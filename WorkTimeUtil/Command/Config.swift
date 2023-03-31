import Foundation

fileprivate let defaults = UserDefaults(suiteName: "com.emanuelmairoll.worktimeutil")!

func config(key: String?, value: String?) {
    guard let key = key else {
        printConfigKeys()
        return
    }

    switch key {
    case "absenceIOCreds":
        setAndValidateConfigValue(key: key, value: value, validationFunction: isValidAbsenceIOCreds, errorMessage: "Invalid AbsenceIO credentials format. It should be in the format: <ID>:<KEY>")
    case "workHoursPerWeek":
        setAndValidateConfigValue(key: key, value: value, validationFunction: isValidWorkHoursPerWeek, errorMessage: "Invalid workHoursPerWeek value. It should be an integer.")
    case "removeLunchBreak":
        setAndValidateConfigValue(key: key, value: value, validationFunction: isValidRemoveLunchBreak, errorMessage: "Invalid removeLunchBreak value. It should be either 'true' or 'false'.")
    default:
        print("Invalid configuration key.")
        exit(1)
    }
}

private func printConfigKeys() {
    let keys = [
        "absenceIOCreds",
        "workHoursPerWeek",
        "removeLunchBreak"
    ]

    print("Available configuration keys:")
    for key in keys {
        print("- \(key)")
    }
}

private func setAndValidateConfigValue(key: String, value: String?, validationFunction: (String) -> Bool, errorMessage: String) {
    if let value = value {
        if validationFunction(value) {
            defaults.set(value, forKey: key)
            print("\(key) set to '\(value)'.")
        } else {
            print(errorMessage)
            exit(1)
        }
    } else {
        if let existingValue = defaults.string(forKey: key) {
            print("\(key): \(existingValue)")
        } else {
            print("No value set for key '\(key)'.")
        }
    }
}

private func isValidAbsenceIOCreds(_ creds: String) -> Bool {
    let credsComponents = creds.split(separator: ":")
    return credsComponents.count == 2
}

private func isValidWorkHoursPerWeek(_ hours: String) -> Bool {
    return Int(hours) != nil
}

private func isValidRemoveLunchBreak(_ value: String) -> Bool {
    return value.lowercased() == "true" || value.lowercased() == "false"
}

func getAbsenceIOCreds() -> String? {
    return defaults.string(forKey: "absenceIOCreds")
}

func getWorkHoursPerWeek() -> Double? {
    return defaults.double(forKey: "workHoursPerWeek")
}

func getRemoveLunchBreak() -> Bool? {
    return defaults.bool(forKey: "removeLunchBreak")
}

