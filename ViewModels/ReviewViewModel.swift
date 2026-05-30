import Foundation
import Combine

/// ReviewViewModel manages the rating and comment input state for creating a review.
@MainActor
final class ReviewViewModel: ObservableObject {
    @Published var rating: Int = 5 // Default rating
    @Published var comment: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    @Published var isSuccess: Bool = false
    
    private let reviewRepository: ReviewRepositoryProtocol
    
    init(reviewRepository: ReviewRepositoryProtocol = ReviewRepository()) {
        self.reviewRepository = reviewRepository
    }
    
    /// Checks basic validations.
    var isReviewValid: Bool {
        return (1...5).contains(rating) && !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Submits the review for a specific listing.
    /// - Parameter listingId: Target listing ID.
    /// - Returns: The updated Listing object returned by the backend.
    func submitReview(listingId: String) async -> Listing? {
        guard isReviewValid else {
            self.errorMessage = "Please enter a review comment."
            self.showErrorAlert = true
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        var updatedListing: Listing? = nil
        
        do {
            updatedListing = try await reviewRepository.createReview(
                listingId: listingId,
                rating: rating,
                comment: comment
            )
            self.isSuccess = true
            // Reset inputs after success
            self.rating = 5
            self.comment = ""
        } catch {
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
        }
        
        isLoading = false
        return updatedListing
    }
}
