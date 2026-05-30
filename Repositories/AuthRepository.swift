import Foundation

/// Protocol defining authentication methods for mock-testability.
protocol AuthRepositoryProtocol {
    func register(username: String, email: String, password: String) async throws -> AuthResponse
    func login(email: String, password: String) async throws -> AuthResponse
}

/// AuthRepository coordinates credentials submission to login/register endpoints.
final class AuthRepository: AuthRepositoryProtocol {
    private let client: APIClient
    
    init(client: APIClient = .shared) {
        self.client = client
    }
    
    func register(username: String, email: String, password: String) async throws -> AuthResponse {
        let payload: [String: String] = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: payload)
        let endpoint = APIEndpoint.register(body: bodyData)
        
        return try await client.request(endpoint)
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let payload: [String: String] = [
            "email": email,
            "password": password
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: payload)
        let endpoint = APIEndpoint.login(body: bodyData)
        
        return try await client.request(endpoint)
    }
}
