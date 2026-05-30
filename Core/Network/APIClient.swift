import Foundation

/// EmptyResponse is a helper type for API requests that return no body or a success confirmation.
struct EmptyResponse: Codable {
    let success: Bool?
    let message: String?
}

/// APIClient executes network requests defined by APIEndpoint, automatically handles authorization,
/// evaluates status codes, and decodes response payloads.
final class APIClient {
    static let shared = APIClient()
    
    private let decoder: JSONDecoder
    
    private init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .useDefaultKeys
    }
    
    /// Executes a request and decodes the response body into the designated Decodable type.
    /// - Parameter endpoint: The configured endpoint.
    /// - Returns: A decoded object of type T.
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        // Read stored token if available
        let token = KeychainManager.shared.getToken()
        
        let urlRequest: URLRequest
        do {
            urlRequest = try endpoint.asURLRequest(token: token)
        } catch {
            throw NetworkError.badURL
        }
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw NetworkError.requestFailed(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Handle non-2xx HTTP status codes
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                // If unauthorized, wipe expired credentials from Keychain
                KeychainManager.shared.clearUserSession()
                throw NetworkError.unauthorized
            }
            
            // Try parsing a custom error payload from Node.js (e.g., { "error": "Reason" } or { "message": "Reason" })
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let errorMsg = errorJson["error"] as? String {
                    throw NetworkError.serverError(errorMsg)
                } else if let message = errorJson["message"] as? String {
                    throw NetworkError.serverError(message)
                }
            }
            
            throw NetworkError.serverError("Request failed with status code \(httpResponse.statusCode)")
        }
        
        // If data is empty and the caller expects EmptyResponse, synthesize a blank success struct
        if data.isEmpty && T.self == EmptyResponse.self {
            return EmptyResponse(success: true, message: "Action succeeded") as! T
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            // Log raw response for debugging parsing errors
            if let rawString = String(data: data, encoding: .utf8) {
                print("Decoding failed. Raw string: \(rawString)")
            }
            throw NetworkError.decodingError(error)
        }
    }
}
