import Foundation

func pushToAbsence(_ parameters: [String], calendar: CalendarManager, absenceAPI api: AbsenceAPI) async {
    do {
        // Fetch the users
        let usersResponse = try await api.getUsers()
        let me = usersResponse.data.first { $0._id == api.me }!
        let approver = usersResponse.data.first { $0._id == me.approverId }!

        // Fetch the reasons
        let reasonsResponse = try await api.getReasons()
        let reasons = reasonsResponse.data.reduce(into: [String: Reason]()) {
            $0[$1._id] = $1
        }

        for parameter in parameters {
            // Parse the time range from the input parameters
            guard let (startDate, endDate) = parseDateParameter(parameter) else {
                print("Invalid command. Usage: worktimeutil push [W|W<n>[/<yy>]|M|M<n>[/<yy>]]")
                exit(1)
            }

            // Fetch the work events using the CalendarManager instance
            let unstretchedWorkEvents = calendar.fetchEvents(startDate: startDate, endDate: endDate)
            let nonUnionWorkEvents = unstretchedWorkEvents.map { $0.isWork || true ? WorkEvent(startDate: $0.startDate.cropTime(), endDate: $0.endDate.cropTime().plusOneDay(), type: $0.type, commentary: $0.commentary) : $0 }
            var workEvents: [WorkEvent] = []

            for event in nonUnionWorkEvents {
                if let existingEventIndex = workEvents.firstIndex(where: { $0.startDate == event.startDate }) {
                    if event.type == .office && workEvents[existingEventIndex].type == .homeOffice {
                        workEvents[existingEventIndex] = event
                    }
                } else {
                    workEvents.append(event)
                }
            }

            // Fetch the absences for the user using the AbsenceAPI instance
            let filter = Filter(start: startDate, end: endDate, assignedToId: me._id)
            let absencesResponse = try await api.getAbsences(request: .init(filter: filter))
            let myAbsences = absencesResponse.data

            // Compare the work events with the absences and identify the missing absences
            struct MissingAbsence {
                let startDate: Date
                let endDate: Date
                let reason: ID
                let commentary: String?
            }

            var missingAbsences: [MissingAbsence] = []

            for event in workEvents {
                if myAbsences.contains(where: { $0.start == event.startDate && $0.end == event.endDate }) {
                    continue
                }

                switch event.type {
                case .office, .companyEvent, .meeting:
                    continue
                case .homeOffice:
                    missingAbsences.append(MissingAbsence(startDate: event.startDate, endDate: event.endDate, reason: reasons.first { $1.name == "Homeoffice" }!.key, commentary: event.commentary))
                case .vacation:
                    missingAbsences.append(MissingAbsence(startDate: event.startDate, endDate: event.endDate, reason: reasons.first { $1.name == "Vacation" }!.key, commentary: event.commentary))
                case .compensatory:
                    missingAbsences.append(MissingAbsence(startDate: event.startDate, endDate: event.endDate, reason: reasons.first { $1.name == "Compensatory time" }!.key, commentary: event.commentary))
                default:
                    continue
                }
            }

            let offDutyReasonID = reasons.first { $1.name == "Off duty due to part-time work agreement" }!.key

            // Add missing "Off Duty" absences for weekdays with no work events
            let calendar = Calendar.gmt
            var currentDate = startDate
            while currentDate < endDate {
                if !CalUtil.isWeekend(date: currentDate) {
                    let hasWorkEvent = workEvents.contains(where: { $0.startDate <= currentDate && $0.endDate > currentDate })
                    let hasOffDutyAbsence = myAbsences.contains(where: { $0.start == currentDate && $0.reasonId == offDutyReasonID })

                    if !hasWorkEvent && !hasOffDutyAbsence {
                        missingAbsences.append(MissingAbsence(startDate: currentDate.cropTime(), endDate: currentDate.cropTime().plusOneDay(), reason: offDutyReasonID, commentary: nil))
                    }
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }

            missingAbsences.sort { $0.startDate < $1.startDate }

            let df = DateFormatter()
            df.timeZone = TimeZone.current
            df.dateStyle = .medium
            df.timeStyle = .none

            guard missingAbsences.count > 0 else {
                print("No missing absences for '\(parameter)':")
                continue
            }

            // List the missing absences on the console
            print("Missing absences for '\(parameter)':")
            for (index, m) in missingAbsences.enumerated() {
                let startDate = df.string(from: m.startDate)
                let endDate = df.string(from: m.endDate)
                let reason = reasons[m.reason]!.name
                let commentary = m.commentary

                print("\(index + 1). Start: \(startDate), End: \(endDate), Reason: \(reason)" + (commentary != nil ? ", Commentary: \(commentary!)" : ""))
            }

            // Ask the user for acknowledgment
            print("Do you want to create these absences? (y/N)")
            if let input = readLine(), input.lowercased() == "y" {
                // Create the missing absences using the AbsenceAPI instance
                for m in missingAbsences {
                    let createRequest = CreateRequest(assignedToId: me._id, approverId: reasons[m.reason]!.requiresApproval ? approver._id : nil, start: m.startDate, end: m.endDate, reasonId: m.reason, commentary: m.commentary)
                    let _ = try await api.createAbsence(request: createRequest)
                }

                print("Successfully created \(missingAbsences.count) missing absences for '\(parameter)'.")
            } else {
                print("Aborted creating missing absences for '\(parameter)'.")
            }
        }

    } catch {
        print("Error while fetching or creating absences: \(error.localizedDescription)")
    }
}
