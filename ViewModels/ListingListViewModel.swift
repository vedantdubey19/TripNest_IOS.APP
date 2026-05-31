import Foundation
import Combine

/// ListingListViewModel manages the state for browsing travel listings, wishlists, and user bookings.
@MainActor
final class ListingListViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    
    // UI Filters
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    
    // Starred Favorites & Bookings State
    @Published var starredListingIds: Set<String> = []
    @Published var bookings: [Booking] = []
    
    /// Categories presented in the top scroll view filter.
    let categories = ["All", "Stays", "Beachfront", "Mountain", "Trending", "Cabins"]
    
    private let listingRepository: ListingRepositoryProtocol
    
    init(listingRepository: ListingRepositoryProtocol = ListingRepository()) {
        self.listingRepository = listingRepository
        loadLocalData()
    }
    
    /// Loads user preferences and reservation history from LocalStoreManager
    func loadLocalData() {
        self.starredListingIds = LocalStoreManager.shared.getFavorites()
        self.bookings = LocalStoreManager.shared.getBookings()
    }
    
    /// Fetches all listings from the repository.
    func fetchListings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.listings = try await listingRepository.getListings()
        } catch {
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
        }
        
        isLoading = false
    }
    
    // MARK: - Favorites Management
    
    func isFavorite(listingId: String) -> Bool {
        starredListingIds.contains(listingId)
    }
    
    func toggleFavorite(listingId: String) {
        if starredListingIds.contains(listingId) {
            starredListingIds.remove(listingId)
        } else {
            starredListingIds.insert(listingId)
        }
        LocalStoreManager.shared.saveFavorites(starredListingIds)
    }
    
    /// Retrieves listings that have been starred by the user
    var starredListings: [Listing] {
        listings.filter { starredListingIds.contains($0.id) }
    }
    
    // MARK: - Bookings Management
    
    func addBooking(listing: Listing, checkIn: Date, checkOut: Date, totalPrice: Double, currency: String, currencyIcon: String) {
        let booking = Booking(
            listingId: listing.id,
            listingTitle: listing.title,
            listingImageURL: listing.image.url,
            location: listing.location,
            country: listing.country,
            checkInDate: checkIn,
            checkOutDate: checkOut,
            totalPrice: totalPrice,
            currency: currency,
            currencyIcon: currencyIcon
        )
        LocalStoreManager.shared.addBooking(booking)
        self.bookings = LocalStoreManager.shared.getBookings()
    }
    
    // MARK: - Filtering Logic
    
    /// Filtered list based on search term and selected category tag.
    var filteredListings: [Listing] {
        var results = listings
        
        // Search filter (matches title, location, or country)
        if !searchText.isEmpty {
            results = results.filter { listing in
                listing.title.localizedCaseInsensitiveContains(searchText) ||
                listing.location.localizedCaseInsensitiveContains(searchText) ||
                listing.country.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Category filter (mock logic based on categories)
        if selectedCategory != "All" {
            results = results.filter { listing in
                switch selectedCategory {
                case "Beachfront":
                    return listing.description.localizedCaseInsensitiveContains("beach") || listing.title.localizedCaseInsensitiveContains("beach")
                case "Mountain":
                    return listing.description.localizedCaseInsensitiveContains("mountain") || listing.description.localizedCaseInsensitiveContains("cabin") || listing.title.localizedCaseInsensitiveContains("mountain")
                case "Cabins":
                    return listing.description.localizedCaseInsensitiveContains("cabin") || listing.title.localizedCaseInsensitiveContains("cabin")
                case "Trending":
                    return listing.price > 150.0 // Higher tier properties as trending
                case "Stays":
                    return true // All listings are stays
                default:
                    return true
                }
            }
        }
        
        return results
    }
}
