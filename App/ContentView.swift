import SwiftUI

public struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // ViewModels to share across views
    @StateObject private var listViewModel = ListingListViewModel()
    
    public init() {}
    
    public var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                TabView {
                    // Explore Tab
                    HomeView()
                        .environmentObject(listViewModel)
                        .tabItem {
                            Label("Explore", systemImage: "safari.fill")
                        }
                    
                    // Map Tab
                    ListingsMapView()
                        .environmentObject(listViewModel)
                        .tabItem {
                            Label("Map", systemImage: "map.fill")
                        }
                    
                    // Profile Tab
                    ProfileView()
                        .environmentObject(listViewModel)
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle.fill")
                        }
                }
                .tint(.blue) // Premium navigation tint
                .onAppear {
                    #if os(iOS)
                    // Set TabBar appearance for dark mode compatibility and sleek styling
                    let appearance = UITabBarAppearance()
                    appearance.configureWithDefaultBackground()
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                    UITabBar.appearance().standardAppearance = appearance
                    #endif
                }
            } else {
                LoginView()
            }
        }
        .animation(.default, value: authViewModel.isAuthenticated)
    }
}

#if os(iOS)
#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
#endif
