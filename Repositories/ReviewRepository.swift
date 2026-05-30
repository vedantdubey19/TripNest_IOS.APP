import Foundation

/// Protocol defining review operations for mock-testability.
protocol ReviewRepositoryProtocol {
    func createReview(listingId: String, rating: Int, comment: String) async throws -> Listing
    func deleteReview(listingId: String, reviewId: String) async throws -> EmptyResponse
}

/// ReviewRepository coordinates adding reviews and deleting them via APIClient.
final class ReviewRepository: ReviewRepositoryProtocol {
    private let client: APIClient
    
    init(client: APIClient = .shared) {
        self.client = client
    }
    
    func createReview(listingId: String, rating: Int, comment: String) async throws -> Listing {
        let payload: [String: Any] = [
            "rating": rating,
            "comment": comment
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: payload)
        let endpoint = APIEndpoint.createReview(listingId: listingId, body: bodyData)
        
        return try await client.request(endpoint)
    }
    
    func deleteReview(listingId: String, reviewId: String) async throws -> EmptyResponse {
        let endpoint = APIEndpoint.deleteReview(listingId: listingId, reviewId: reviewId)
        return try await client.request(endpoint)
    }
}
