import Foundation
import Combine
import CoreLocation

/// CreateListingViewModel manages the form state, validation, and submission for creating and editing a listing.
@MainActor
final class CreateListingViewModel: ObservableObject {
    // Form properties
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var priceString: String = ""
    @Published var location: String = ""
    @Published var country: String = ""
    
    // Image selection properties
    @Published var selectedImageData: Data? = nil
    @Published var currentImageUrl: String? = nil
    @Published var currentImageFilename: String? = nil
    
    // UI state properties
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    @Published var isSuccess: Bool = false
    
    private let listingRepository: ListingRepositoryProtocol
    private let imageRepository: ImageRepositoryProtocol
    
    init(
        listingRepository: ListingRepositoryProtocol = ListingRepository(),
        imageRepository: ImageRepositoryProtocol = ImageRepository()
    ) {
        self.listingRepository = listingRepository
        self.imageRepository = imageRepository
    }
    
    /// Populates form fields for editing an existing listing.
    func setupForEditing(_ listing: Listing) {
        self.title = listing.title
        self.description = listing.description
        self.priceString = String(format: "%.2f", listing.price)
        self.location = listing.location
        self.country = listing.country
        self.currentImageUrl = listing.image.url
        self.currentImageFilename = listing.image.filename
        self.selectedImageData = nil
    }
    
    /// Checks basic fields validation and parses numbers.
    var isFormValid: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let price = Double(priceString), price > 0,
              !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        // Either we have a new image selected, or we are editing and have an existing image
        return selectedImageData != nil || currentImageUrl != nil
    }
    
    /// Uses CLGeocoder to verify that MapKit can find coordinates for the listing location.
    func verifyLocation() async -> Bool {
        let geocoder = CLGeocoder()
        let fullAddress = "\(location), \(country)"
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(fullAddress)
            return placemarks.first?.location != nil
        } catch {
            return false
        }
    }
    
    /// Submits the listing (creation or updating).
    /// - Parameters:
    ///   - isEditing: Boolean indicating whether to call update or create.
    ///   - editListingId: The ID of the listing if updating.
    func submitListing(isEditing: Bool, editListingId: String? = nil) async {
        guard isFormValid else {
            self.errorMessage = "Please fill in all fields correctly."
            self.showErrorAlert = true
            return
        }
        
        guard let price = Double(priceString) else { return }
        
        isLoading = true
        errorMessage = nil
        
        // 1. Verify Geocoding first to ensure map placement works
        let isLocationValid = await verifyLocation()
        guard isLocationValid else {
            self.errorMessage = "Could not verify location. Please enter a valid city and country."
            self.showErrorAlert = true
            self.isLoading = false
            return
        }
        
        do {
            var finalImage: Listing.ListingImage
            
            // 2. Upload image to Cloudinary if new image is selected
            if let imageData = selectedImageData {
                finalImage = try await imageRepository.uploadImage(data: imageData)
            } else if let existingUrl = currentImageUrl, let existingFilename = currentImageFilename {
                // Reuse existing image
                finalImage = Listing.ListingImage(url: existingUrl, filename: existingFilename)
            } else {
                throw NetworkError.serverError("Please select a listing image.")
            }
            
            // 3. Save listing details to backend database
            if isEditing, let id = editListingId {
                _ = try await listingRepository.updateListing(
                    id: id,
                    title: title,
                    description: description,
                    price: price,
                    location: location,
                    country: country,
                    image: finalImage
                )
            } else {
                _ = try await listingRepository.createListing(
                    title: title,
                    description: description,
                    price: price,
                    location: location,
                    country: country,
                    image: finalImage
                )
            }
            
            self.isSuccess = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
        }
        
        isLoading = false
    }
}
