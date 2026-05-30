import Foundation
import Combine

/// ListingListViewModel manages the state for browsing travel listings.
@MainActor
final class ListingListViewModel: ObservableObject {
    @Published var listings: [Listing] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    
    // UI Filters
    @Published var searchText: String = ""
    @Published var selectedCategory: String = "All"
    
    /// Categories presented in the top scroll view filter.
    let categories = ["All", "Stays", "Beachfront", "Mountain", "Trending", "Cabins"]
    
    private let listingRepository: ListingRepositoryProtocol
    
    init(listingRepository: ListingRepositoryProtocol = ListingRepository()) {
        self.listingRepository = listingRepository
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
