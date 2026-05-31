import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var listViewModel: ListingListViewModel
    
    // Filters listings owned by the logged-in user
    private var myListings: [Listing] {
        guard let currentUserId = authViewModel.currentUser?.id else { return [] }
        return listViewModel.listings.filter { $0.owner.id == currentUserId }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background dark tone
                Color(red: 0.05, green: 0.05, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // User Avatar & Credentials Card
                        VStack(spacing: 16) {
                            // Profile Avatar Placeholder
                            Circle()
                                .fill(
                                    LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .frame(width: 90, height: 90)
                                .overlay(
                                    Text(String(authViewModel.currentUser?.username.prefix(1) ?? "U").uppercased())
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: Color.blue.opacity(0.2), radius: 10, y: 5)
                            
                            VStack(spacing: 4) {
                                Text(authViewModel.currentUser?.username ?? "User Profile")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(authViewModel.currentUser?.email ?? "email@example.com")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            // Stats Indicator Row
                            HStack(spacing: 40) {
                                VStack(spacing: 4) {
                                    Text("\(myListings.count)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("My Nests")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                
                                VStack(spacing: 4) {
                                    Text("\(listViewModel.listings.count)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Text("Total Stays")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.white.opacity(0.02))
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.04), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // Trips & Bookings Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trips & Bookings")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            NavigationLink(destination: BookingHistoryView().environmentObject(listViewModel)) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 46, height: 46)
                                        
                                        Image(systemName: "suitcase.rolling.fill")
                                            .foregroundColor(.white)
                                            .font(.title3)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Booking History")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Text("\(listViewModel.bookings.count) stay reservations")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.02))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                                )
                                .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // User's Own Listings section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("My Listed Nests")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            if myListings.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "house.lodge")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("You haven't listed any stays yet.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(Color.white.opacity(0.01))
                                .cornerRadius(16)
                                .padding(.horizontal)
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(myListings) { listing in
                                        NavigationLink(destination: ListingDetailView(listingId: listing.id)) {
                                            HStack(spacing: 12) {
                                                // Image thumbnail
                                                AsyncImage(url: URL(string: listing.image.url)) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                } placeholder: {
                                                    Color.white.opacity(0.05)
                                                }
                                                .frame(width: 70, height: 70)
                                                .cornerRadius(12)
                                                .clipped()
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(listing.title)
                                                        .font(.subheadline)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.white)
                                                        .lineLimit(1)
                                                    
                                                    Text("\(listing.location), \(listing.country)")
                                                        .font(.caption2)
                                                        .foregroundColor(.blue)
                                                    
                                                    Text(String(format: "$%.0f / night", listing.price))
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.gray)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.footnote)
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(10)
                                            .background(Color.white.opacity(0.02))
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Logout Action
                        Button(action: {
                            authViewModel.logout()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log Out")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayModeInline()
            .task {
                await listViewModel.fetchListings()
            }
        }
    }
}

#if os(iOS)
#Preview {
    let mockAuth = AuthViewModel()
    mockAuth.currentUser = User(id: "101", username: "VocalTraveler", email: "traveler@gmail.com")
    mockAuth.isAuthenticated = true
    
    let mockList = ListingListViewModel()
    mockList.listings = [
        Listing(
            id: "1",
            title: "Cozy Redwood Cabin",
            description: "",
            price: 130.0,
            location: "Redwoods",
            country: "USA",
            image: Listing.ListingImage(url: "", filename: ""),
            owner: User(id: "101", username: "VocalTraveler", email: ""),
            reviews: []
        )
    ]
    
    return ProfileView()
        .environmentObject(mockAuth)
        .environmentObject(mockList)
        .preferredColorScheme(.dark)
}
#endif
