import Foundation
import CoreLocation

/// Listing represents a travel or stay property, including its basic metadata, image details, reviews, and host owner.
struct Listing: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let price: Double
    let location: String
    let country: String
    let image: ListingImage
    let owner: User
    let reviews: [Review]
    let latitude: Double?
    let longitude: Double?
    
    /// ListingImage models the image structure returned by Cloudinary (URL and ID/filename).
    struct ListingImage: Codable, Hashable {
        let url: String
        let filename: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case description
        case price
        case location
        case country
        case image
        case owner
        case reviews
        case latitude
        case longitude
    }
    
    init(id: String, title: String, description: String, price: Double, location: String, country: String, image: ListingImage, owner: User, reviews: [Review], latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.location = location
        self.country = country
        self.image = image
        self.owner = owner
        self.reviews = reviews
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        self.price = try container.decode(Double.self, forKey: .price)
        self.location = try container.decode(String.self, forKey: .location)
        self.country = try container.decode(String.self, forKey: .country)
        self.image = try container.decode(ListingImage.self, forKey: .image)
        self.reviews = (try? container.decode([Review].self, forKey: .reviews)) ?? []
        self.latitude = try? container.decode(Double.self, forKey: .latitude)
        self.longitude = try? container.decode(Double.self, forKey: .longitude)
        
        // Resolve ID
        if let idFromUnderscore = try? container.decode(String.self, forKey: .id) {
            self.id = idFromUnderscore
        } else {
            let fallbackContainer = try decoder.container(keyedBy: FallbackCodingKeys.self)
            if let idFromFlat = try? fallbackContainer.decode(String.self, forKey: .id) {
                self.id = idFromFlat
            } else {
                throw DecodingError.keyNotFound(CodingKeys.id, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not find either '_id' or 'id' in JSON payload."))
            }
        }
        
        // Decode owner. If populated, parse the User object; otherwise, create a placeholder from the owner ID.
        if let populatedOwner = try? container.decode(User.self, forKey: .owner) {
            self.owner = populatedOwner
        } else if let ownerId = try? container.decode(String.self, forKey: .owner) {
            self.owner = User(id: ownerId, username: "Host", email: "")
        } else {
            throw DecodingError.typeMismatch(User.self, DecodingError.Context(codingPath: decoder.codingPath + [CodingKeys.owner], debugDescription: "Owner property is neither a User object nor a String ID."))
        }
    }
    
    private enum FallbackCodingKeys: String, CodingKey {
        case id
    }
    
    /// Full address text helper used for geocoding queries
    var fullAddress: String {
        "\(location), \(country)"
    }
}
