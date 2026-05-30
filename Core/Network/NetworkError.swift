import Foundation

/// NetworkError represents failures that can occur during networking operations.
enum NetworkError: Error, LocalizedError {
    case badURL
    case invalidResponse
    case requestFailed(Error)
    case decodingError(Error)
    case unauthorized
    case serverError(String)
    case noData
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .badURL:
            return "The request URL is invalid. Please contact support."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .requestFailed(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse the server response: \(error.localizedDescription)"
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .serverError(let message):
            return message
        case .noData:
            return "No data was returned by the server."
        case .unknown:
            return "An unknown networking error occurred."
        }
    }
}
