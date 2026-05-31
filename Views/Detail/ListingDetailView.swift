import SwiftUI
import MapKit

struct ListingDetailView: View {
    let listingId: String
    
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var listViewModel: ListingListViewModel
    
    @StateObject private var detailViewModel = ListingDetailViewModel()
    @StateObject private var reviewViewModel = ReviewViewModel()
    
    @Environment(\.dismiss) var dismiss
    @State private var showEditSheet = false
    @State private var showBookingSheet = false
    @State private var coordinate: CLLocationCoordinate2D? = nil
    
    // For Map camera control
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    var isOwner: Bool {
        guard let currentId = authViewModel.currentUser?.id,
              let ownerId = detailViewModel.listing?.owner.id else { return false }
        return currentId == ownerId
    }
    
    var body: some View {
        ZStack {
            // Base background
            listViewModel.themeBg
                .ignoresSafeArea()
            
            if detailViewModel.isLoading && detailViewModel.listing == nil {
                ProgressView("Fetching listing profile...")
                    .tint(.blue)
            } else if let listing = detailViewModel.listing {
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Image Carousel Header
                            ImageCarouselView(imageUrls: [listing.image.url])
                                .frame(height: 320)
                                .ignoresSafeArea(edges: .top)
                            
                            VStack(alignment: .leading, spacing: 20) {
                                // Title & Host section
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("\(listing.location), \(listing.country)")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        
                                        Spacer()
                                        
                                        // Price Info
                                        Text(String(format: "$%.0f", listing.price))
                                            .font(.title2)
                                            .fontWeight(.black)
                                            .foregroundColor(listViewModel.themeText)
                                        Text("/ night")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text(listing.title)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(listViewModel.themeText)
                                    
                                    Text("Hosted by \(listing.owner.username)")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                        .padding(.top, 2)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                // Description Segment
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("About this space")
                                        .font(.headline)
                                        .foregroundColor(listViewModel.themeText)
                                    
                                    Text(listing.description)
                                        .font(.body)
                                        .foregroundColor(.gray)
                                        .lineSpacing(4)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                // Map Preview Section
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Where you'll be")
                                        .font(.headline)
                                        .foregroundColor(listViewModel.themeText)
                                    
                                    if let coord = coordinate {
                                        Map(position: $cameraPosition) {
                                            Marker(listing.location, coordinate: coord)
                                                .tint(.blue)
                                        }
                                        .frame(height: 180)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                    } else {
                                        HStack {
                                            Spacer()
                                            VStack(spacing: 8) {
                                                ProgressView()
                                                    .tint(.white)
                                                Text("Resolving coordinate location...")
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                        }
                                        .frame(height: 180)
                                        .background(Color.white.opacity(0.02))
                                        .cornerRadius(16)
                                    }
                                }
                                .onAppear {
                                    geocodeLocation(address: listing.fullAddress)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                // Add Review Form
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Leave a Review")
                                        .font(.headline)
                                        .foregroundColor(listViewModel.themeText)
                                    
                                    VStack(spacing: 12) {
                                        // Interactive Stars selector
                                        HStack {
                                            Text("Rating:")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 6) {
                                                ForEach(1...5, id: \.self) { star in
                                                    Button(action: { reviewViewModel.rating = star }) {
                                                        Image(systemName: star <= reviewViewModel.rating ? "star.fill" : "star")
                                                            .font(.title3)
                                                            .foregroundColor(star <= reviewViewModel.rating ? .yellow : .gray.opacity(0.4))
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // Review input text
                                        TextField("Write your review comment...", text: $reviewViewModel.comment, axis: .vertical)
                                            .lineLimit(3...5)
                                            .padding()
                                            .foregroundColor(listViewModel.themeText)
                                            .background(listViewModel.themeCardBg)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(listViewModel.themeBorder, lineWidth: 1)
                                            )
                                        
                                        // Submit Button
                                        Button(action: {
                                            Task {
                                                if let updated = await reviewViewModel.submitReview(listingId: listing.id) {
                                                    detailViewModel.listing = updated
                                                }
                                            }
                                        }) {
                                            HStack {
                                                if reviewViewModel.isLoading {
                                                    ProgressView()
                                                        .tint(.white)
                                                        .padding(.trailing, 8)
                                                }
                                                Text("Submit Review")
                                                    .fontWeight(.bold)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(
                                                reviewViewModel.isReviewValid ?
                                                LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing) :
                                                LinearGradient(colors: [.gray.opacity(0.2)], startPoint: .leading, endPoint: .trailing)
                                            )
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                        }
                                        .disabled(!reviewViewModel.isReviewValid || reviewViewModel.isLoading)
                                    }
                                    .padding(16)
                                    .background(listViewModel.themeCardBg)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(listViewModel.themeBorder, lineWidth: 1)
                                    )
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.1))
                                
                                // Listing Reviews List
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("Reviews (\(listing.reviews.count))")
                                        .font(.headline)
                                        .foregroundColor(listViewModel.themeText)
                                    
                                    if listing.reviews.isEmpty {
                                        Text("No reviews yet. Be the first to share your experience!")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .italic()
                                            .padding(.vertical, 8)
                                    } else {
                                        VStack(spacing: 12) {
                                            ForEach(listing.reviews) { review in
                                                ReviewRowView(
                                                    review: review,
                                                    currentUserId: authViewModel.currentUser?.id,
                                                    onDelete: {
                                                        Task {
                                                            await detailViewModel.deleteReview(reviewId: review.id)
                                                        }
                                                    }
                                                )
                                            }
                                        }
                                    }
                                }
                                .padding(.bottom, 40)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Floating Bottom Book Now bar (only if not listing owner)
                    if !isOwner {
                        VStack(spacing: 0) {
                            Divider()
                                .background(Color.white.opacity(0.08))
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Booking Option")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    HStack(alignment: .bottom, spacing: 2) {
                                        Text(String(format: "$%.0f", listing.price))
                                            .font(.title2)
                                            .fontWeight(.black)
                                            .foregroundColor(listViewModel.themeText)
                                        Text("/ night")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.bottom, 2)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: { showBookingSheet = true }) {
                                    Text("Book Stay")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 28)
                                        .padding(.vertical, 14)
                                        .background(
                                            LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        )
                                        .cornerRadius(14)
                                        .shadow(color: Color.blue.opacity(0.3), radius: 8, y: 4)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(listViewModel.themeBg)
                        }
                    }
                }
            } else {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Could not find property details.")
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
        .navigationBarTitleDisplayModeInline()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    if let listing = detailViewModel.listing {
                        // Star toggle button
                        Button(action: {
                            listViewModel.toggleFavorite(listingId: listing.id)
                        }) {
                            Image(systemName: listViewModel.isFavorite(listingId: listing.id) ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundColor(listViewModel.isFavorite(listingId: listing.id) ? .yellow : listViewModel.themeText)
                        }
                    }
                    
                    if isOwner {
                        Menu {
                            Button(action: { showEditSheet = true }) {
                                Label("Edit Stay", systemImage: "pencil")
                            }
                            Button(role: .destructive, action: {
                                Task {
                                    await detailViewModel.deleteListing()
                                }
                            }) {
                                Label("Delete Stay", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .task {
            // Load listing detail parameters
            await detailViewModel.fetchListingDetails(id: listingId)
        }
        .sheet(isPresented: $showEditSheet) {
            if let listing = detailViewModel.listing {
                CreateListingView(editingListing: listing)
                    .environmentObject(detailViewModel)
            }
        }
        .sheet(isPresented: $showBookingSheet) {
            if let listing = detailViewModel.listing {
                BookingSheetView(listing: listing)
                    .environmentObject(listViewModel)
            }
        }
        .onChange(of: detailViewModel.isDeleted) { _, deleted in
            if deleted {
                dismiss() // Pop back to grid catalog
            }
        }
        .alert("Action Failed", isPresented: $detailViewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(detailViewModel.errorMessage ?? "An operations error occurred.")
        }
        .alert("Submission Failed", isPresented: $reviewViewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(reviewViewModel.errorMessage ?? "Could not post your review.")
        }
    }
    
    /// Converts the location and country string into Map coordinates dynamically
    private func geocodeLocation(address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            guard let loc = placemarks?.first?.location?.coordinate else { return }
            
            withAnimation(.easeInOut) {
                self.coordinate = loc
                self.cameraPosition = .region(MKCoordinateRegion(
                    center: loc,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
        }
    }
}

#if os(iOS)
#Preview {
    NavigationStack {
        ListingDetailView(listingId: "1")
            .environmentObject(AuthViewModel())
            .environmentObject(ListingListViewModel())
    }
}
#endif
