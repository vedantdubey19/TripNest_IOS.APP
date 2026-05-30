import Foundation
import Security

/// KeychainManager is a helper class to securely store, retrieve, and delete sensitive data
/// such as JWT authentication tokens in the iOS Keychain.
final class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.tripnest.app"
    private let tokenKey = "jwt_token"
    private let usernameKey = "current_username"
    private let emailKey = "current_email"
    private let userIdKey = "current_user_id"
    
    private init() {}
    
    /// Saves a string value securely in the Keychain.
    @discardableResult
    func save(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // Delete any existing item with the same key first to avoid conflicts
        delete(key)
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock // Available while device is unlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Reads a string value securely from the Keychain.
    func read(for key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecReturnData: kCFBooleanTrue as Any,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    /// Deletes a value from the Keychain.
    func delete(_ key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - JWT Token Helpers
    
    @discardableResult
    func saveToken(_ token: String) -> Bool {
        return save(token, for: tokenKey)
    }
    
    func getToken() -> String? {
        return read(for: tokenKey)
    }
    
    func deleteToken() {
        delete(tokenKey)
    }
    
    // MARK: - User Session Helpers
    
    func saveUserSession(id: String, username: String, email: String) {
        save(id, for: userIdKey)
        save(username, for: usernameKey)
        save(email, for: emailKey)
    }
    
    func getUserSession() -> (id: String, username: String, email: String)? {
        guard let id = read(for: userIdKey),
              let username = read(for: usernameKey),
              let email = read(for: emailKey) else {
            return nil
        }
        return (id, username, email)
    }
    
    func clearUserSession() {
        deleteToken()
        delete(userIdKey)
        delete(usernameKey)
        delete(emailKey)
    }
}
