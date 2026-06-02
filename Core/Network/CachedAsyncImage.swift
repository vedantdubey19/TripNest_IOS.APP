import SwiftUI

/// Thread-safe in-memory cache for images fetched from network.
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        // Cache limits to avoid high memory pressure (e.g., max 100 images)
        cache.countLimit = 100
    }
    
    func get(forKey key: URL) -> UIImage? {
        cache.object(forKey: key as NSURL)
    }
    
    func set(_ image: UIImage, forKey key: URL) {
        cache.setObject(image, forKey: key as NSURL)
    }
}

/// The loading state of a CachedAsyncImage.
enum CachedAsyncImagePhase {
    case empty
    case success(Image)
    case failure(Error)
}

/// A drop-in replacement for SwiftUI's AsyncImage that caches downloaded images in-memory to prevent lag.
struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let content: (CachedAsyncImagePhase) -> Content
    
    @State private var phase: CachedAsyncImagePhase = .empty
    @State private var loadedUrl: URL? = nil
    
    init(url: URL?, @ViewBuilder content: @escaping (CachedAsyncImagePhase) -> Content) {
        self.url = url
        self.content = content
    }
    
    var body: some View {
        content(phase)
            .onAppear {
                loadImage()
            }
            .onChange(of: url) { _, _ in
                loadImage()
            }
    }
    
    private func loadImage() {
        guard let url = url else {
            phase = .empty
            return
        }
        
        // Skip if already loaded
        if url == loadedUrl { return }
        
        // Retrieve from cache if available
        if let cachedImage = ImageCache.shared.get(forKey: url) {
            phase = .success(Image(uiImage: cachedImage))
            loadedUrl = url
            return
        }
        
        phase = .empty
        loadedUrl = url
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    if self.loadedUrl == url {
                        self.phase = .failure(error)
                    }
                }
                return
            }
            
            guard let data = data, let loadedImage = UIImage(data: data) else {
                DispatchQueue.main.async {
                    if self.loadedUrl == url {
                        self.phase = .failure(URLError(.cannotDecodeContentData))
                    }
                }
                return
            }
            
            // Cache the loaded image
            ImageCache.shared.set(loadedImage, forKey: url)
            
            DispatchQueue.main.async {
                if self.loadedUrl == url {
                    self.phase = .success(Image(uiImage: loadedImage))
                }
            }
        }.resume()
    }
}
