import Foundation

struct WorkEvent {
    let startDate: Date
    let endDate: Date
    let type: WorkType
}

enum WorkType {
    case office, homeOffice, meeting, companyEvent, vacation, sick
}

extension WorkEvent {
    var isWork: Bool {
        get {
            type == .office || type == .homeOffice || type == .meeting
        }
    }
}
