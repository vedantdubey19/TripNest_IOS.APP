import SwiftUI
import MapKit

/// Structure combining a Listing with its resolved GPS coordinates for MapKit rendering.
struct ListingPin: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let listing: Listing
}

struct ListingsMapView: View {
    @EnvironmentObject var listViewModel: ListingListViewModel
    
    // Caches geocoded coordinates to prevent redundant CLGeocoder calls
    @State private var coordinateCache: [String: CLLocationCoordinate2D] = [:]
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedPin: ListingPin? = nil
    
    @StateObject private var locationManager = LocationManager()
    @State private var hasCenteredOnUser = false
    
    private var pins: [ListingPin] {
        listViewModel.listings.compactMap { listing in
            guard let coord = coordinateCache[listing.id] else { return nil }
            return ListingPin(id: listing.id, coordinate: coord, listing: listing)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Interactive Map View
                Map(position: $cameraPosition, selection: $selectedPin) {
                    UserAnnotation() // Shows the blue pulse for user location
                    
                    ForEach(pins) { pin in
                        // Use Annotation for highly customizable Airbnb style pins
                        Annotation(pin.listing.title, coordinate: pin.coordinate) {
                            NavigationLink(destination: ListingDetailView(listingId: pin.listing.id)) {
                                VStack(spacing: 2) {
                                    // Price Bubble Tag
                                    Text(String(format: "$%.0f", pin.listing.price))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            LinearGradient(colors: [.blue, .indigo], startPoint: .top, endPoint: .bottom)
                                        )
                                        .cornerRadius(8)
                                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "triangle.fill")
                                        .font(.system(size: 8))
                                        .foregroundColor(.indigo)
                                        .rotationEffect(.degrees(180))
                                        .offset(y: -4)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .tag(pin)
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .all, showsTraffic: false))
                
                // Skeleton Loader Overlay if coordinates are still being resolved
                if pins.isEmpty && !listViewModel.listings.isEmpty {
                    VStack {
                        ProgressView("Resolving map positions...")
                            .tint(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                }
            }
            .navigationTitle("Explore Map")
            .navigationBarTitleDisplayModeInline()
            .onAppear {
                locationManager.startUpdatingLocation()
            }
            .onDisappear {
                locationManager.stopUpdatingLocation()
            }
            .task {
                await listViewModel.fetchListings()
                geocodeAllListings()
            }
            .onChange(of: listViewModel.listings) { _, newListings in
                geocodeAllListings()
            }
            .onChange(of: locationManager.location) { _, newLocation in
                if let userLoc = newLocation, !hasCenteredOnUser {
                    withAnimation(.spring()) {
                        self.cameraPosition = .region(MKCoordinateRegion(
                            center: userLoc.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                        ))
                        self.hasCenteredOnUser = true
                    }
                }
            }
        }
    }
    
    /// Iterates through listings and geocodes any that do not exist in cache
    private func geocodeAllListings() {
        let geocoder = CLGeocoder()
        
        for listing in listViewModel.listings {
            // Skip if already in cache
            guard coordinateCache[listing.id] == nil else { continue }
            
            let fullAddress = listing.fullAddress
            geocoder.geocodeAddressString(fullAddress) { placemarks, error in
                if let coord = placemarks?.first?.location?.coordinate {
                    DispatchQueue.main.async {
                        withAnimation {
                            self.coordinateCache[listing.id] = coord
                            
                            // Adjust map window center if this is the first pin geocoded and we haven't centered on user location
                            if self.coordinateCache.count == 1 && !self.hasCenteredOnUser {
                                self.cameraPosition = .region(MKCoordinateRegion(
                                    center: coord,
                                    span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
                                ))
                            }
                        }
                    }
                }
            }
        }
    }
}

// Conformance required for map selection tracking
extension ListingPin: Equatable {
    static func == (lhs: ListingPin, rhs: ListingPin) -> Bool {
        lhs.id == rhs.id
    }
}

extension ListingPin: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#if os(iOS)
#Preview {
    let mockVM = ListingListViewModel()
    mockVM.listings = [
        Listing(
            id: "1",
            title: "Cozy Cabin",
            description: "",
            price: 120.0,
            location: "Seattle",
            country: "USA",
            image: Listing.ListingImage(url: "", filename: ""),
            owner: User(id: "", username: "", email: ""),
            reviews: []
        )
    ]
    return ListingsMapView()
        .environmentObject(mockVM)
        .preferredColorScheme(.dark)
}
#endif
