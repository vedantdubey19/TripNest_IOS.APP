import Foundation
import Combine

/// AuthViewModel manages the global authentication state of the application.
@MainActor
public final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showErrorAlert: Bool = false
    
    private let authRepository: AuthRepositoryProtocol
    
    public init() {
        self.authRepository = AuthRepository()
        checkSession()
    }
    
    /// Checks Keychain for a saved JWT and user details to restore session automatically.
    func checkSession() {
        if KeychainManager.shared.getToken() != nil,
           let session = KeychainManager.shared.getUserSession() {
            self.currentUser = User(id: session.id, username: session.username, email: session.email)
            self.isAuthenticated = true
        } else {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    /// Registers a new user.
    func register(username: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await authRepository.register(username: username, email: email, password: password)
            // Save token and user details to Keychain
            KeychainManager.shared.saveToken(response.token)
            KeychainManager.shared.saveUserSession(id: response.user.id, username: response.user.username, email: response.user.email)
            
            self.currentUser = response.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
            self.isAuthenticated = false
        }
        
        isLoading = false
    }
    
    /// Logs in an existing user.
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await authRepository.login(email: email, password: password)
            // Save token and user details to Keychain
            KeychainManager.shared.saveToken(response.token)
            KeychainManager.shared.saveUserSession(id: response.user.id, username: response.user.username, email: response.user.email)
            
            self.currentUser = response.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
            self.showErrorAlert = true
            self.isAuthenticated = false
        }
        
        isLoading = false
    }
    
    /// Logs out the current user and clears Keychain credentials.
    func logout() {
        KeychainManager.shared.clearUserSession()
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
