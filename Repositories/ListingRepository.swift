import Foundation

/// Protocol defining listing operations for mock-testability.
protocol ListingRepositoryProtocol {
    func getListings() async throws -> [Listing]
    func getListing(id: String) async throws -> Listing
    func createListing(title: String, description: String, price: Double, location: String, country: String, image: Listing.ListingImage) async throws -> Listing
    func updateListing(id: String, title: String, description: String, price: Double, location: String, country: String, image: Listing.ListingImage) async throws -> Listing
    func deleteListing(id: String) async throws -> EmptyResponse
}

/// ListingRepository maps CRUD methods to target backend REST routes via APIClient,
/// with support for offline fallbacks and predefined global destinations.
final class ListingRepository: ListingRepositoryProtocol {
    private let client: APIClient
    
    // Core host user for local mock listings
    private static let mockHost = User(id: "mock_host_id", username: "Local Nest Host", email: "host@tripnest.com")
    
    // High-fidelity pre-populated listings representing famous places requested
    private static let defaultMockListings: [Listing] = [
        // India
        Listing(
            id: "india_taj",
            title: "Taj Mahal View Retreat",
            description: "Experience royal luxury with breathtaking views of the majestic Taj Mahal from your private balcony. Features premium marble finishes and traditional gardens.",
            price: 120.0,
            location: "Agra",
            country: "India",
            image: Listing.ListingImage(
                url: "https://res.cloudinary.com/dy6ybmtf3/image/fetch/https%3A%2F%2Fimages.unsplash.com%2Fphoto-1564507592333-c60657eea523%3Fauto%3Dformat%26fit%3Dcrop%26w%3D800%26q%3D80",
                filename: "india_taj"
            ),
            owner: mockHost,
            reviews: [
                Review(id: "r_taj1", rating: 5, comment: "Absolutely breathtaking views. The hospitality was royal!", author: User(id: "u_taj1", username: "Rajesh", email: ""))
            ]
        ),
        Listing(
            id: "india_udaipur",
            title: "Udaipur Lake Palace Suite",
            description: "Nestled in the center of Lake Pichola, this heritage suite offers unparalleled scenic lake vistas, luxury boat transfers, and royal interior decor.",
            price: 350.0,
            location: "Udaipur",
            country: "India",
            image: Listing.ListingImage(
                url: "https://res.cloudinary.com/dy6ybmtf3/image/fetch/https%3A%2F%2Fimages.unsplash.com%2Fphoto-1590050752117-238cb0fb12b1%3Fauto%3Dformat%26fit%3Dcrop%26w%3D800%26q%3D80",
                filename: "india_udaipur"
            ),
            owner: mockHost,
            reviews: []
        ),
        Listing(
            id: "india_goa",
            title: "Goa Beachfront Cottage",
            description: "Step directly onto the warm sand from this cozy beach cottage. Perfect sunset views, hammock under palm trees, and fresh sea breeze.",
            price: 90.0,
            location: "Goa",
            country: "India",
            image: Listing.ListingImage(
                url: "https://res.cloudinary.com/dy6ybmtf3/image/fetch/https%3A%2F%2Fimages.unsplash.com%2Fphoto-1507525428034-b723cf961d3e%3Fauto%3Dformat%26fit%3Dcrop%26w%3D800%26q%3D80",
                filename: "india_goa"
            ),
            owner: mockHost,
            reviews: []
        ),
        // USA
        Listing(
            id: "usa_canyon",
            title: "Grand Canyon Majestic Lodge",
            description: "A rustic stone lodge perched right on the rim of the Grand Canyon. Enjoy hiking trails at your doorstep, outdoor firepits, and star-filled night skies.",
            price: 220.0,
            location: "Arizona",
            country: "USA",
            image: Listing.ListingImage(
                url: "https://res.cloudinary.com/dy6ybmtf3/image/fetch/https%3A%2F%2Fimages.unsplash.com%2Fphoto-1474044159687-1ee9f3a51722%3Fauto%3Dformat%26fit%3Dcrop%26w%3D800%26q%3D80",
                filename: "usa_canyon"
            ),
            owner: mockHost,
            reviews: [
                Review(id: "r_can1", rating: 5, comment: "Best sunset I have ever seen. Waking up to the canyon is magical.", author: User(id: "u_can1", username: "Emily", email: ""))
            ]
        ),
        Listing(
            id: "usa_malibu",
            title: "Malibu Luxury Beachfront Villa",
            description: "A stunning architectural glass villa directly overlooking Malibu beach. Private infinity pool, state-of-the-art kitchen, and direct ocean access.",
            price: 450.0,
            location: "Malibu",
            country: "USA",
            image: Listing.ListingImage(
                url: "https://res.cloudinary.com/dy6ybmtf3/image/fetch/https%3A%2F%2Fimages.unsplash.com%2Fphoto-1512917774080-9991f1c4c750%3Fauto%3Dformat%26fit%3Dcrop%26w%3D800%26q%3D80",
                filename: "usa_malibu"
            ),
            owner: mockHost,
            reviews: []
        ),
        Listing(
            id: "usa_manhattan",
            title: "Manhattan Sky Penthouse",
            description: "High-rise luxury penthouse in the heart of New York City. Floor-to-ceiling windows with panoramic skyline views, private terrace, and modern style.",
            price: 280.0,
            location: "New York",
            country: "USA",
            image: Listing.ListingImage(
                url: "https://res.cloudinary.com/dy6ybmtf3/image/fetch/https%3A%2F%2Fimages.unsplash.com%2Fphoto-1502672260266-1c1ef2d93688%3Fauto%3Dformat%26fit%3Dcrop%26w%3D800%26q%3D80",
                filename: "usa_manhattan"
            ),
            owner: mockHost,
            reviews: []
        ),
        // Europe
        Listing(
            id: "europe_paris",
            title: "Eiffel Tower View Apartment",
            description: "Chic Parisian apartment featuring classic French balconies with a direct, unobstructed view of the Eiffel Tower. Perfect for romantic getaways.",
            price: 180.0,
            location: "Paris",
            country: "France",
            image: Listing.ListingImage(
                url: "https://res.cloudinary.com/dy6ybmtf3/image/fetch/https%3A%2F%2Fimages.unsplash.com%2Fphoto-1502602898657-3e91760cbb34%3Fauto%3Dformat%26fit%3Dcrop%26w%3D800%26q%3D80",
                filename: "europe_paris"
            ),
            owner: mockHost,
            reviews: [
                Review(id: "r_par1", rating: 5, comment: "I could watch the Eiffel Tower sparkle all night from bed!", author: User(id: "u_par1", username: "Chloe", email: ""))
            ]
        ),
        Listing(
            id: "europe_rome",
            title: "Colosseum Luxury Suite",
            description: "A beautifully restored historic suite located just steps from the Colosseum. Experience ancient history with all modern luxury comforts.",
            price: 160.0,
            location: "Rome",
            country: "Italy",
            image: Listing.ListingImage(
                url: "https://res.cloudinary.com/dy6ybmtf3/image/fetch/https%3A%2F%2Fimages.unsplash.com%2Fphoto-1552832230-c0197dd311b5%3Fauto%3Dformat%26fit%3Dcrop%26w%3D800%26q%3D80",
                filename: "europe_rome"
            ),
            owner: mockHost,
            reviews: []
        ),
        Listing(
            id: "europe_swiss",
            title: "Swiss Alps Cozy Wooden Cabin",
            description: "Escape to a snow-covered mountain cabin in Zermatt. Enjoy spectacular Matterhorn views, cozy wood-burning fireplace, and ski-in/ski-out access.",
            price: 210.0,
            location: "Zermatt",
            country: "Switzerland",
            image: Listing.ListingImage(
                url: "https://res.cloudinary.com/dy6ybmtf3/image/fetch/https%3A%2F%2Fimages.unsplash.com%2Fphoto-1506744038136-46273834b3fb%3Fauto%3Dformat%26fit%3Dcrop%26w%3D800%26q%3D80",
                filename: "europe_swiss"
            ),
            owner: mockHost,
            reviews: []
        )
    ]
    
    // In-memory list representing current status of listings
    private var localListings: [Listing] = ListingRepository.defaultMockListings
    
    init(client: APIClient = .shared) {
        self.client = client
    }
    
    func getListings() async throws -> [Listing] {
        let endpoint = APIEndpoint.getListings
        do {
            let remoteListings: [Listing] = try await client.request(endpoint)
            
            // Merge remote listings with local fallback listings
            var combined = localListings
            for remote in remoteListings {
                if let idx = combined.firstIndex(where: { $0.id == remote.id }) {
                    combined[idx] = remote
                } else {
                    combined.append(remote)
                }
            }
            self.localListings = combined
            return self.localListings
        } catch {
            print("ListingRepository: API failed, returning local fallback database. Error: \(error.localizedDescription)")
            return localListings
        }
    }
    
    func getListing(id: String) async throws -> Listing {
        let endpoint = APIEndpoint.getListing(id: id)
        do {
            return try await client.request(endpoint)
        } catch {
            print("ListingRepository: API get detail failed, checking local list. Error: \(error.localizedDescription)")
            if let local = localListings.first(where: { $0.id == id }) {
                return local
            }
            throw error
        }
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
        
        // Generate placeholder local listing in case network fails
        let localId = UUID().uuidString
        let currentUserSession = KeychainManager.shared.getUserSession()
        let ownerUser = currentUserSession.map { User(id: $0.id, username: $0.username, email: $0.email) } ?? ListingRepository.mockHost
        
        let fallbackListing = Listing(
            id: localId,
            title: title,
            description: description,
            price: price,
            location: location,
            country: country,
            image: image,
            owner: ownerUser,
            reviews: []
        )
        
        do {
            let created: Listing = try await client.request(endpoint)
            localListings.append(created)
            return created
        } catch {
            print("ListingRepository: Create failed, saving locally only. Error: \(error.localizedDescription)")
            localListings.append(fallbackListing)
            return fallbackListing
        }
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
        
        do {
            let updated: Listing = try await client.request(endpoint)
            if let idx = localListings.firstIndex(where: { $0.id == id }) {
                localListings[idx] = updated
            }
            return updated
        } catch {
            print("ListingRepository: Update failed, modifying local state only. Error: \(error.localizedDescription)")
            
            if let idx = localListings.firstIndex(where: { $0.id == id }) {
                let existing = localListings[idx]
                let updatedLocal = Listing(
                    id: existing.id,
                    title: title,
                    description: description,
                    price: price,
                    location: location,
                    country: country,
                    image: image,
                    owner: existing.owner,
                    reviews: existing.reviews
                )
                localListings[idx] = updatedLocal
                return updatedLocal
            }
            throw error
        }
    }
    
    func deleteListing(id: String) async throws -> EmptyResponse {
        let endpoint = APIEndpoint.deleteListing(id: id)
        do {
            let response: EmptyResponse = try await client.request(endpoint)
            localListings.removeAll(where: { $0.id == id })
            return response
        } catch {
            print("ListingRepository: Delete failed, deleting local item only. Error: \(error.localizedDescription)")
            localListings.removeAll(where: { $0.id == id })
            return EmptyResponse(success: true, message: "Deleted locally")
        }
    }
}
