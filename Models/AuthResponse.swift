import Foundation

/// AuthResponse represents the JSON response returned by authentication endpoints (/api/auth/login and /api/auth/register).
struct AuthResponse: Codable {
    let token: String
    let user: User
}
