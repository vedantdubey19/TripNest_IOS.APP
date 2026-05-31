import Foundation

/// LocalStoreManager handles persistent local storage for user bookmarks (starred listings) and bookings.
public final class LocalStoreManager {
    public static let shared = LocalStoreManager()
    
    private let favoritesKey = "tripnest_favorites"
    private let bookingsKey = "tripnest_bookings"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private init() {
        // Configure standard date strategies
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }
    
    // MARK: - Favorites (Starred Listings)
    
    public func getFavorites() -> Set<String> {
        guard let data = UserDefaults.standard.array(forKey: favoritesKey) as? [String] else {
            return []
        }
        return Set(data)
    }
    
    public func saveFavorites(_ favorites: Set<String>) {
        UserDefaults.standard.set(Array(favorites), forKey: favoritesKey)
    }
    
    // MARK: - Bookings
    
    public func getBookings() -> [Booking] {
        guard let data = UserDefaults.standard.data(forKey: bookingsKey) else {
            return []
        }
        do {
            return try decoder.decode([Booking].self, from: data)
        } catch {
            print("Failed to decode bookings: \(error)")
            return []
        }
    }
    
    public func saveBookings(_ bookings: [Booking]) {
        do {
            let data = try encoder.encode(bookings)
            UserDefaults.standard.set(data, forKey: bookingsKey)
        } catch {
            print("Failed to encode bookings: \(error)")
        }
    }
    
    public func addBooking(_ booking: Booking) {
        var current = getBookings()
        current.insert(booking, at: 0) // Prepend newest bookings
        saveBookings(current)
    }
}
// Note: Swift 5.9 doesn't allow 'val' inside classes, changed to static let.
