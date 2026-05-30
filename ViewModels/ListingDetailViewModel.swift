import Foundation
import Combine

/// ListingDetailViewModel manages state and operations for the detail view of a single listing.
@MainActor
final class ListingDetailViewModel: ObservableObject {
    @Published var listing: Listing? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    @Published var isDeleted: Bool = false
    
    private let listingRepository: ListingRepositoryProtocol
    private let reviewRepository: ReviewRepositoryProtocol
    
    init(
        listingRepository: ListingRepositoryProtocol = ListingRepository(),
        reviewRepository: ReviewRepositoryProtocol = ReviewRepository()
    ) {
        self.listingRepository = listingRepository
        self.reviewRepository = reviewRepository
    }
    
    /// Loads the latest detailed copy of the listing, including populated reviews.
    func fetchListingDetails(id: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.listing = try await listingRepository.getListing(id: id)
        } catch {
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
        }
        
        isLoading = false
    }
    
    /// Deletes the current listing (only authorized for listing owner).
    func deleteListing() async {
        guard let listingId = listing?.id else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await listingRepository.deleteListing(id: listingId)
            self.isDeleted = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
        }
        
        isLoading = false
    }
    
    /// Deletes a review from the listing (only authorized for review author/listing owner depending on backend policy).
    func deleteReview(reviewId: String) async {
        guard let listingId = listing?.id else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await reviewRepository.deleteReview(listingId: listingId, reviewId: reviewId)
            // Reload listing details to show updated reviews list
            await fetchListingDetails(id: listingId)
        } catch {
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
        }
        
        isLoading = false
    }
}
