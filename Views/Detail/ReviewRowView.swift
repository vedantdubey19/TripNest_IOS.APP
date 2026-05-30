import SwiftUI

struct ReviewRowView: View {
    let review: Review
    let currentUserId: String?
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Author Avatar Placeholder & Info
                HStack(spacing: 8) {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(review.author.username.prefix(1)).uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(review.author.username)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        // Rating Stars
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= review.rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundColor(star <= review.rating ? .yellow : .gray.opacity(0.5))
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Show trash icon if the logged-in user is the author of this review
                if let currentId = currentUserId, review.author.id == currentId {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundColor(.red.opacity(0.8))
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            
            // Review Text Comment
            Text(review.comment)
                .font(.footnote)
                .foregroundColor(.gray)
                .lineLimit(4)
                .padding(.leading, 4)
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

#if os(iOS)
#Preview {
    VStack {
        ReviewRowView(
            review: Review(
                id: "1",
                rating: 4,
                comment: "Beautiful location, very quiet and close to the lake. The host was prompt and helpful.",
                author: User(id: "u100", username: "Jane Doe", email: "jane@doe.com")
            ),
            currentUserId: "u100",
            onDelete: {}
        )
        .padding()
        
        ReviewRowView(
            review: Review(
                id: "2",
                rating: 5,
                comment: "Absolutely perfect stay!",
                author: User(id: "u200", username: "Alex Smith", email: "")
            ),
            currentUserId: "u100",
            onDelete: {}
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
#endif
