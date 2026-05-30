import Foundation

/// Review represents a rating and comment left by a user on a travel listing.
struct Review: Codable, Identifiable, Hashable {
    let id: String
    let rating: Int // Range: 1 to 5
    let comment: String
    let author: User
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case rating
        case comment
        case author
    }
    
    init(id: String, rating: Int, comment: String, author: User) {
        self.id = id
        self.rating = rating
        self.comment = comment
        self.author = author
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.rating = try container.decode(Int.self, forKey: .rating)
        self.comment = try container.decode(String.self, forKey: .comment)
        
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
        
        // Decode author. If the backend populated the User reference, decode it as User.
        // If it's a raw String (ObjectId reference), create a placeholder User object.
        if let populatedAuthor = try? container.decode(User.self, forKey: .author) {
            self.author = populatedAuthor
        } else if let authorId = try? container.decode(String.self, forKey: .author) {
            self.author = User(id: authorId, username: "Guest User", email: "")
        } else {
            throw DecodingError.typeMismatch(User.self, DecodingError.Context(codingPath: decoder.codingPath + [CodingKeys.author], debugDescription: "Author property is neither a User object nor a String ID."))
        }
    }
    
    private enum FallbackCodingKeys: String, CodingKey {
        case id
    }
}
