import SwiftUI

public struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // ViewModels to share across views
    @StateObject private var listViewModel = ListingListViewModel()
    
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                TabView(selection: $selectedTab) {
                    // Explore Tab
                    HomeView(selectedTab: $selectedTab)
                        .environmentObject(listViewModel)
                        .tabItem {
                            Label("Explore", systemImage: "safari.fill")
                        }
                        .tag(0)
                    
                    // Map Tab
                    ListingsMapView()
                        .environmentObject(listViewModel)
                        .tabItem {
                            Label("Map", systemImage: "map.fill")
                        }
                        .tag(1)
                    
                    // Starred Tab
                    FavoritesView()
                        .environmentObject(listViewModel)
                        .tabItem {
                            Label("Starred", systemImage: "star.fill")
                        }
                        .tag(2)
                    
                    // Profile Tab
                    ProfileView()
                        .environmentObject(listViewModel)
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle.fill")
                        }
                        .tag(3)
                }
                .tint(.blue) // Premium navigation tint
                .preferredColorScheme(listViewModel.isDarkMode ? .dark : .light)
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
