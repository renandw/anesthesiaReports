//
//  AuthStorage.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 26/01/26.
//


import Foundation
import Security

final class AuthStorage {

    private let service = Bundle.main.bundleIdentifier! + ".auth"

    private enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
    }

    // MARK: - Save

    func save(accessToken: String, refreshToken: String) {
        save(accessToken, for: Keys.accessToken)
        save(refreshToken, for: Keys.refreshToken)
    }

    // MARK: - Get

    func getAccessToken() -> String? {
        get(for: Keys.accessToken)
    }

    func getRefreshToken() -> String? {
        get(for: Keys.refreshToken)
    }

    // MARK: - Clear

    func clear() {
        delete(for: Keys.accessToken)
        delete(for: Keys.refreshToken)
    }

    // MARK: - Keychain helpers

    private func save(_ value: String, for key: String) {
        let data = Data(value.utf8)
        delete(for: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private func get(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard
            status == errSecSuccess,
            let data = result as? Data
        else { return nil }

        return String(decoding: data, as: UTF8.self)
    }

    private func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
