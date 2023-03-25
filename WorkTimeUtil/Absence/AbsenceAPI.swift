import Foundation
import SwiftyHawk

struct AbsenceAPI {
    public let me: ID

    private let baseURL = URL(string: "https://app.absence.io")!
    private let credentials: Hawk.Credentials

    init(id: String, key: String) {
        self.me = id
        self.credentials = Hawk.Credentials(id: id, key: key, algoritm: .sha256)
    }

    private func performRequest<T: Decodable>(path: String, method: String, body: Encodable) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let headerResult = try? Hawk.Client.header(uri: url.absoluteString,
                                                   method: method,
                                                   credentials: credentials,
                                                   nonce: UUID().uuidString)
        if let headerValue = headerResult?.headerValue {
            request.addValue(headerValue, forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601ex
        request.httpBody = try encoder.encode(body)

        //print(String(data: request.httpBody!, encoding: .utf8) ?? "")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Invalid HTTP response", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: nil)
        }

        //print(String(data: data, encoding: .utf8) ?? "")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601ex
        let responseJSON = try decoder.decode(T.self, from: data)
        return responseJSON
    }

}

extension AbsenceAPI {
    public func getAbsences(request: ListRequest = ListRequest()) async throws -> Response<[Absence]> {
        let path = "/api/v2/absences"
        let method = "POST"
        let response: Response<[Absence]> = try await performRequest(path: path, method: method, body: request)
        return response
    }

    public func getDepartments(request: ListRequest = ListRequest()) async throws -> Response<[Department]> {
        let path = "/api/v2/departments"
        let method = "POST"
        let response: Response<[Department]> = try await performRequest(path: path, method: method, body: request)
        return response
    }

    public func getUsers(request: ListRequest = ListRequest()) async throws -> Response<[User]> {
        let path = "/api/v2/users"
        let method = "POST"
        let response: Response<[User]> = try await performRequest(path: path, method: method, body: request)
        return response
    }

    public func getReasons(request: ListRequest = ListRequest()) async throws -> Response<[Reason]> {
        let path = "/api/v2/reasons"
        let method = "POST"
        let response: Response<[Reason]> = try await performRequest(path: path, method: method, body: request)
        return response
    }

    public func createAbsence(request: CreateRequest) async throws -> Absence {
        let path = "/api/v2/absences/create"
        let method = "POST"
        let response: Absence = try await performRequest(path: path, method: method, body: request)
        return response
    }
}
