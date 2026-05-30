import Foundation

/// HTTPMethod defines the HTTP request types.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// APIEndpoint defines all target endpoints for the TripNest REST API.
enum APIEndpoint {
    // Auth Endpoints
    case register(body: Data)
    case login(body: Data)
    
    // Listing Endpoints
    case getListings
    case getListing(id: String)
    case createListing(body: Data)
    case updateListing(id: String, body: Data)
    case deleteListing(id: String)
    
    // Review Endpoints
    case createReview(listingId: String, body: Data)
    case deleteReview(listingId: String, reviewId: String)
    
    /// The default base URL string for the backend.
    /// Update this value if your local server uses a different port or if deploying to staging/production.
    static var baseURLString: String = "http://localhost:3000/api"
    
    /// Path suffix for each endpoint
    var path: String {
        switch self {
        case .register:
            return "/auth/register"
        case .login:
            return "/auth/login"
        case .getListings, .createListing:
            return "/listings"
        case .getListing(let id), .updateListing(let id, _), .deleteListing(let id):
            return "/listings/\(id)"
        case .createReview(let listingId, _):
            return "/listings/\(listingId)/reviews"
        case .deleteReview(let listingId, let reviewId):
            return "/listings/\(listingId)/reviews/\(reviewId)"
        }
    }
    
    /// HTTP method for each endpoint
    var method: HTTPMethod {
        switch self {
        case .getListings, .getListing:
            return .get
        case .register, .login, .createListing, .createReview:
            return .post
        case .updateListing:
            return .put
        case .deleteListing, .deleteReview:
            return .delete
        }
    }
    
    /// The HTTP body for the request.
    var body: Data? {
        switch self {
        case .register(let body), .login(let body), .createListing(let body), .updateListing(_, let body), .createReview(_, let body):
            return body
        default:
            return nil
        }
    }
    
    /// Builds a URLRequest using the designated base URL.
    /// Adds standard Content-Type headers for JSON.
    func asURLRequest(token: String? = nil) throws -> URLRequest {
        guard let baseURL = URL(string: APIEndpoint.baseURLString) else {
            throw NetworkError.badURL
        }
        
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Add content type if sending body data
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Attach authorization header if token is present
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        return request
    }
}
