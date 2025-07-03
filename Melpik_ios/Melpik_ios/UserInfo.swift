import Foundation

struct UserInfo: Codable {
    let id: String
    let email: String
    let name: String
    let token: String
    let refreshToken: String?
    let expiresAt: Date?

    var isTokenExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
} 