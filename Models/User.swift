import Foundation

/// User represents a registered member in the TripNest system.
public struct User: Codable, Identifiable, Hashable {
    public let id: String
    public let username: String
    public let email: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case email
    }
    
    public init(id: String, username: String, email: String) {
        self.id = id
        self.username = username
        self.email = email
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.username = try container.decode(String.self, forKey: .username)
        self.email = try container.decode(String.self, forKey: .email)
        
        // MongoDB returns "_id", but sometimes our client/DTOs use "id". Support both.
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
    }
    
    private enum FallbackCodingKeys: String, CodingKey {
        case id
    }
}
