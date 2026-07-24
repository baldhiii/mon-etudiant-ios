import Foundation
import Security

/// Thread-safe Keychain wrapper for the API access token.
/// The token is NEVER stored in UserDefaults.
enum TokenStore {
    private static let service = Bundle.main.bundleIdentifier ?? "com.monEtudiant.app"
    private static let account = "api_access_token"

    @discardableResult
    static func save(_ token: String) throws -> Bool {
        guard let data = token.data(using: .utf8) else { return false }
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw Error.keychainError(addStatus) }
        } else if status != errSecSuccess {
            throw Error.keychainError(status)
        }
        return true
    }

    static func load() -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete() {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    enum Error: Swift.Error {
        case keychainError(OSStatus)
    }
}
