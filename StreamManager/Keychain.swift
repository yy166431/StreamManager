import Foundation
import Security

enum Keychain {
    static func set(_ value: String, for key: String) {
        let data = value.data(using: .utf8) ?? Data()
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(q as CFDictionary)
        SecItemAdd(q as CFDictionary, nil)
    }

    static func get(_ key: String) -> String {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        SecItemCopyMatching(q as CFDictionary, &out)
        guard let data = out as? Data, let s = String(data: data, encoding: .utf8) else { return "" }
        return s
    }
}

