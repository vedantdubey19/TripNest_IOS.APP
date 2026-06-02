import SwiftUI

struct ImageCarouselView: View {
    let imageUrls: [String]
    
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // TabView Page Style
            TabView(selection: $currentIndex) {
                ForEach(0..<imageUrls.count, id: \.self) { index in
                    CachedAsyncImage(url: URL(string: imageUrls[index])) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .overlay(ProgressView().tint(.white))
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
                                        .font(.largeTitle)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .tag(index)
                }
            }
            #if os(iOS)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            #endif // Custom dots overlay below
            
            // Bottom Gradient Overlay for readability
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
            
            // Custom Carousel Dot Indicators
            if imageUrls.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<imageUrls.count, id: \.self) { index in
                        Circle()
                            .fill(currentIndex == index ? Color.blue : Color.white.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentIndex == index ? 1.2 : 1.0)
                            .animation(.spring(), value: currentIndex)
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }
}

#if os(iOS)
#Preview {
    ImageCarouselView(imageUrls: [
        "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1510798831971-661eb04b3739?auto=format&fit=crop&w=800&q=80"
    ])
    .frame(height: 300)
    .preferredColorScheme(.dark)
}
#endif
