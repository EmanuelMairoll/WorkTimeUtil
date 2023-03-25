import Foundation
import EventKit

class CalendarManager {
    let eventStore = EKEventStore()

    deinit {
        eventStore.reset()
    }

    func requestAccess() async -> Bool {
        let eventStore = EKEventStore()
        return await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: .event) { granted, error in
                continuation.resume(returning: granted)
            }
        }
    }

    func fetchEvents(startDate: Date, endDate: Date) -> [WorkEvent] {
        let predicate = eventStore.predicateForEvents(withStart: startDate,
                                                       end: endDate,
                                                       calendars: [getWorkTimeCalendar()])
        let events = eventStore.events(matching: predicate)

        var workEvents: [WorkEvent] = []

        for event in events {
            let type: WorkType?

            switch event.title {
            case "Office":
                type = .office
            case "Home Office":
                type = .homeOffice
            case "Company Event", "Team Event":
                type = .companyEvent
            case "Meeting", "QBR":
                type = .meeting
            case "Sick", "sick":
                type = .sick
            case "Vacation":
                type = .vacation
            default:
                type = nil
                print("Warning: Unknown event found. Title: \(event.title!), Start Date: \(event.startDate!), End Date: \(event.endDate!)")
            }

            if let type = type {
                workEvents.append(WorkEvent(startDate: event.startDate, endDate: event.endDate, type: type))
            }
        }

        return workEvents
    }


    func getWorkTimeCalendar() -> EKCalendar {
        guard let calendar = eventStore.calendars(for: .event).first(where: { $0.title == "Work Time" }) else {
            fatalError("Calendar 'Work Time' not found.")
        }
        return calendar
    }
}
