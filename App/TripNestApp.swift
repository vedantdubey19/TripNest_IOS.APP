import SwiftUI

@main
struct TripNestApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.dark) // Lock app to dark theme for our high-end aesthetic
        }
    }
}
