import Foundation

/// Protocol defining listing operations for mock-testability.
protocol ListingRepositoryProtocol {
    func getListings() async throws -> [Listing]
    func getListing(id: String) async throws -> Listing
    func createListing(title: String, description: String, price: Double, location: String, country: String, image: Listing.ListingImage) async throws -> Listing
    func updateListing(id: String, title: String, description: String, price: Double, location: String, country: String, image: Listing.ListingImage) async throws -> Listing
    func deleteListing(id: String) async throws -> EmptyResponse
}

/// ListingRepository maps CRUD methods to target backend REST routes via APIClient.
final class ListingRepository: ListingRepositoryProtocol {
    private let client: APIClient
    
    init(client: APIClient = .shared) {
        self.client = client
    }
    
    func getListings() async throws -> [Listing] {
        let endpoint = APIEndpoint.getListings
        return try await client.request(endpoint)
    }
    
    func getListing(id: String) async throws -> Listing {
        let endpoint = APIEndpoint.getListing(id: id)
        return try await client.request(endpoint)
    }
    
    func createListing(title: String, description: String, price: Double, location: String, country: String, image: Listing.ListingImage) async throws -> Listing {
        let payload: [String: Any] = [
            "title": title,
            "description": description,
            "price": price,
            "location": location,
            "country": country,
            "image": [
                "url": image.url,
                "filename": image.filename
            ]
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: payload)
        let endpoint = APIEndpoint.createListing(body: bodyData)
        
        return try await client.request(endpoint)
    }
    
    func updateListing(id: String, title: String, description: String, price: Double, location: String, country: String, image: Listing.ListingImage) async throws -> Listing {
        let payload: [String: Any] = [
            "title": title,
            "description": description,
            "price": price,
            "location": location,
            "country": country,
            "image": [
                "url": image.url,
                "filename": image.filename
            ]
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: payload)
        let endpoint = APIEndpoint.updateListing(id: id, body: bodyData)
        
        return try await client.request(endpoint)
    }
    
    func deleteListing(id: String) async throws -> EmptyResponse {
        let endpoint = APIEndpoint.deleteListing(id: id)
        return try await client.request(endpoint)
    }
}
