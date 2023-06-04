import CryptoKit
import Foundation

struct HawkCredentials {
    let id: String
    let key: String
}

enum HawkError: Error {
    case invalidUrl
    case missingHeader
}

class HawkClient {
    static func header(uri: String, method: String, credentials: HawkCredentials, nonce: String) throws -> String {
        guard let url = URL(string: uri) else {
            throw HawkError.invalidUrl
        }

        let timestamp = UInt64(Date().timeIntervalSince1970)
        let normalizedString = try buildNormalizedString(method: method, url: url, credentials: credentials, timestamp: timestamp, nonce: nonce)
        let keyData = Data(credentials.key.utf8)
        let symmetricKey = SymmetricKey(data: keyData)
        let hmac = HMAC<SHA256>.authenticationCode(for: Data(normalizedString.utf8), using: symmetricKey)
        let mac = Data(hmac).base64EncodedString()

        return "Hawk id=\"\(credentials.id)\", ts=\"\(timestamp)\", nonce=\"\(nonce)\", mac=\"\(mac)\""
    }

    private static func buildNormalizedString(method: String, url: URL, credentials: HawkCredentials, timestamp: UInt64, nonce: String) throws -> String {
        let host = url.host ?? ""
        let port = url.port ?? (url.scheme == "https" ? 443 : 80)
        let query = url.query.map { "?\($0)" } ?? ""

        let normalized = [
            "hawk.1.header",
            String(timestamp),
            nonce,
            method.uppercased(),
            url.path + query,
            host.lowercased(),
            String(port),
            "",
            "",
        ].joined(separator: "\n")

        return normalized + "\n"
    }
}
