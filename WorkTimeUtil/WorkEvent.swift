import Foundation

struct WorkEvent {
    let startDate: Date
    let endDate: Date
    let type: WorkType
    let commentary: String?
}

enum WorkType {
    case office, homeOffice, meeting, companyEvent, vacation, holiday, compensatory, sick
}

extension WorkEvent {
    var isWork: Bool {
        type == .office || type == .homeOffice || type == .meeting
    }

    var reducesTarget: Bool {
        type == .companyEvent || type == .vacation || type == .holiday || type == .sick
    }
}
