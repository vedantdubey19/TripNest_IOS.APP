import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var listViewModel: ListingListViewModel
    
    // Grid configuration matching HomeView
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background dark shade matching our system
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        if listViewModel.starredListings.isEmpty {
                            VStack(spacing: 18) {
                                Spacer(minLength: 120)
                                
                                // Glowing Placeholder Star
                                ZStack {
                                    Circle()
                                        .fill(Color.yellow.opacity(0.04))
                                        .frame(width: 100, height: 100)
                                        .blur(radius: 8)
                                    
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 54))
                                        .foregroundColor(.yellow.opacity(0.4))
                                        .shadow(color: Color.yellow.opacity(0.2), radius: 10)
                                }
                                
                                Text("No Starred Nests Yet")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Tap the star icon on any unique stay to save it in your favorites collection.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                    .lineSpacing(4)
                            }
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(listViewModel.starredListings) { listing in
                                    NavigationLink(destination: ListingDetailView(listingId: listing.id)) {
                                        ListingCardView(listing: listing)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle("Starred Nests")
            .navigationBarTitleDisplayModeInline()
        }
    }
}

#if os(iOS)
#Preview {
    let mockListVM = ListingListViewModel()
    mockListVM.listings = [
        Listing(
            id: "1",
            title: "Taj Mahal View Retreat",
            description: "Experience royal luxury with views of Taj Mahal.",
            price: 120.0,
            location: "Agra",
            country: "India",
            image: Listing.ListingImage(url: "", filename: ""),
            owner: User(id: "1", username: "Host", email: ""),
            reviews: []
        )
    ]
    mockListVM.starredListingIds = ["1"]
    
    return FavoritesView()
        .environmentObject(mockListVM)
        .preferredColorScheme(.dark)
}
#endif
