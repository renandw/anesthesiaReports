import Foundation
import Security

actor TokenManager {

    static let shared = TokenManager()
    private init() {}

    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"

    // Task compartilhada para refresh em andamento
    private var refreshTask: Task<String, Error>?

    // MARK: - Public API

    /// Retorna um access token válido (refresh automático se necessário)
    func validAccessToken() async throws -> String {
        if let token = loadToken(for: accessTokenKey),
           !isExpired(token: token) {
            return token
        }

        throw AuthError.tokenExpired
    }

    /// Força refresh do access token (usado pelo HTTPClient)
    func forceRefresh() async throws -> String {
        if let task = refreshTask {
            // outro refresh já em andamento → aguarda
            return try await task.value
        }

        guard let refreshToken = loadToken(for: refreshTokenKey) else {
            throw AuthError.notAuthenticated
        }

        let task = Task<String, Error> {
            do {
                let response = try await AuthAPI.refresh(refreshToken: refreshToken)

                saveTokens(
                    accessToken: response.access_token,
                    refreshToken: response.refresh_token
                )

                return response.access_token
            } catch {
                deleteToken(for: accessTokenKey)
                throw error
            }
        }

        refreshTask = task

        defer { refreshTask = nil }

        return try await task.value
    }

    func saveTokens(accessToken: String, refreshToken: String) {
        saveToken(accessToken, for: accessTokenKey)
        saveToken(refreshToken, for: refreshTokenKey)
    }

    /// Remove apenas o access token (sessão expirada, não destrutivo)
    func clearAccessToken() {
        deleteToken(for: accessTokenKey)
    }

    func clearSession() {
        deleteToken(for: accessTokenKey)
        deleteToken(for: refreshTokenKey)
    }

    // MARK: - JWT Helpers

    private func isExpired(token: String) -> Bool {
        let segments = token.split(separator: ".")
        guard segments.count == 3 else { return true }

        let payloadSegment = segments[1]

        var base64 = payloadSegment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard
            let data = Data(base64Encoded: base64),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let exp = json["exp"] as? TimeInterval
        else {
            return true
        }

        let expirationDate = Date(timeIntervalSince1970: exp)
        return expirationDate <= Date()
    }

    // MARK: - Keychain

    private func saveToken(_ token: String, for key: String) {
        let data = Data(token.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadToken(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard
            status == errSecSuccess,
            let data = result as? Data,
            let token = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return token
    }

    private func deleteToken(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
