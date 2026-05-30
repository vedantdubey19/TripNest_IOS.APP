import SwiftUI

struct HomeView: View {
    @EnvironmentObject var listViewModel: ListingListViewModel
    
    @State private var showCreateListingSheet = false
    
    // Grid configuration for iPhone layout (2 columns)
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
                    // Header Brand & Actions
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Find Your Nest")
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Discover unique stays around the world")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search city, country, title...", text: $listViewModel.searchText)
                            .foregroundColor(.white)
                            .tint(.blue)
                        
                        if !listViewModel.searchText.isEmpty {
                            Button(action: { listViewModel.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Scrollable Horizontal Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(listViewModel.categories, id: \.self) { category in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        listViewModel.selectedCategory = category
                                    }
                                }) {
                                    Text(category)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            listViewModel.selectedCategory == category ?
                                            LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                            LinearGradient(colors: [Color.white.opacity(0.05)], startPoint: .leading, endPoint: .trailing)
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(listViewModel.selectedCategory == category ? Color.blue.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    }
                    
                    // Listings Grid
                    ScrollView {
                        if listViewModel.isLoading && listViewModel.listings.isEmpty {
                            VStack {
                                Spacer(minLength: 100)
                                ProgressView("Loading amazing places...")
                                    .tint(.blue)
                                    .foregroundColor(.gray)
                            }
                        } else if listViewModel.filteredListings.isEmpty {
                            VStack(spacing: 16) {
                                Spacer(minLength: 100)
                                Image(systemName: "house.slash")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                Text("No Listings Found")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Try adjusting your search filters.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(listViewModel.filteredListings) { listing in
                                    NavigationLink(destination: ListingDetailView(listingId: listing.id)) {
                                        ListingCardView(listing: listing)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 80) // Padding for FAB space
                        }
                    }
                    .refreshable {
                        await listViewModel.fetchListings()
                    }
                }
                
                // Floating Action Button for Create Listing
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showCreateListingSheet = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("List Property")
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(30)
                            .shadow(color: Color.blue.opacity(0.4), radius: 15, x: 0, y: 10)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .navigationBar) // Hide standard nav bar for custom brand header
            #endif
            .task {
                // Fetch listings on view mount
                await listViewModel.fetchListings()
            }
            .sheet(isPresented: $showCreateListingSheet) {
                CreateListingView()
                    .environmentObject(listViewModel)
            }
            .alert("Load Failed", isPresented: $listViewModel.showErrorAlert) {
                Button("Retry") {
                    Task {
                        await listViewModel.fetchListings()
                    }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(listViewModel.errorMessage ?? "An error occurred while loading listings.")
            }
        }
    }
}

#if os(iOS)
#Preview {
    let mockVM = ListingListViewModel()
    mockVM.listings = [
        Listing(
            id: "1",
            title: "Cozy A-Frame Cabin",
            description: "Nestled in pine woods, this rustic modern A-frame is the perfect getaway with hot tub access.",
            price: 180.0,
            location: "Cascades",
            country: "USA",
            image: Listing.ListingImage(url: "https://images.unsplash.com/photo-1510798831971-661eb04b3739?auto=format&fit=crop&w=800&q=80", filename: "sample_cabin"),
            owner: User(id: "101", username: "Host", email: ""),
            reviews: []
        )
    ]
    return HomeView()
        .environmentObject(mockVM)
        .preferredColorScheme(.dark)
}
#endif
