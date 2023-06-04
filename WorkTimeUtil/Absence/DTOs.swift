import Foundation

typealias ID = String

struct Response<T: Decodable>: Decodable {
    public let skip: Int
    public let limit: Int
    public let count: Int
    public let totalCount: Int
    public let data: T
}

struct Absence: Codable {
    public let _id: ID
    public let start: Date
    public let end: Date
    public let created: Date
    public let modified: Date
    public let daysCount: Int
    public let assignedTo: User?
    public let approver: User?
    public let approverId: ID?
    public let commentary: String?
    public let reason: Reason?
    public let reasonId: ID?
}

struct Department: Codable {
    public let _id: ID
    public let company: String
    public let name: String
}

struct User: Codable {
    public let _id: ID
    public let created: Date
    public let modified: Date
    public let firstName: String
    public let lastName: String
    public let email: String
    public let departmentId: ID?
    public let approverId: ID?

}

struct Reason: Codable {
    public let _id: ID
    public let name: String
    public let modified: Date
    public let requiresApproval: Bool
}

struct ListRequest: Encodable {
    public var skip: Int? = 0
    public var limit: Int? = 50
    public var filter: Filter? = nil
    public var relations: [String] = []
}

struct Filter: Encodable {
    public var start: [String: String]?
    public var end: [String: String]?
    public var assignedToId: ID
    public var assignedToUser: [String: String]?

    enum CodingKeys: String, CodingKey {
        case start
        case end
        case assignedToId
        case assignedToUser = "assignedTo:user._id"
    }

    init(start: Date? = nil, end: Date? = nil, assignedToId: ID, assignedToEmail: String? = nil) {
        if let start {  // yep, that has to be switched around... brain, I know
            self.end = ["$gte": start.ISO8601Format()]
        }

        if let end {
            self.start = ["$lte": end.ISO8601Format()]
        }

        self.assignedToId = assignedToId

        if let assignedToEmail {
            self.assignedToUser = ["email": assignedToEmail]
        }
    }
}

struct CreateRequest: Encodable {
    public var assignedToId: ID
    public var approverId: ID?
    public var start: Date
    public var end: Date
    public var reasonId: ID
    public let commentary: String?
}
