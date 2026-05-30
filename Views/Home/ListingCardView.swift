import SwiftUI

struct ListingCardView: View {
    let listing: Listing
    
    // Computes average rating from reviews array
    private var averageRating: String {
        guard !listing.reviews.isEmpty else { return "New" }
        let sum = listing.reviews.reduce(0.0) { $0 + Double($1.rating) }
        let average = sum / Double(listing.reviews.count)
        return String(format: "%.1f", average)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Listing Image with AsyncImage
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: listing.image.url)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .font(.title)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Rating Overlay Tag
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    Text(averageRating)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(10)
            }
            
            // Listing details
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text("\(listing.location), \(listing.country)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                Text(listing.title)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(listing.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .padding(.top, 2)
                
                HStack(spacing: 4) {
                    Text(String(format: "$%.0f", listing.price))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("night")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(Color.white.opacity(0.02))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
}

#if os(iOS)
#Preview {
    ListingCardView(
        listing: Listing(
            id: "1",
            title: "Charming Beachside Villa",
            description: "A gorgeous seaside escape with direct access to private sand, panoramic sunset views, and luxury pool amenities.",
            price: 245.0,
            location: "Malibu",
            country: "USA",
            image: Listing.ListingImage(url: "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80", filename: "sample_villa"),
            owner: User(id: "101", username: "HostName", email: ""),
            reviews: [
                Review(id: "r1", rating: 5, comment: "Incredible!", author: User(id: "u1", username: "John", email: ""))
            ]
        )
    )
    .preferredColorScheme(.dark)
    .padding()
}
#endif
