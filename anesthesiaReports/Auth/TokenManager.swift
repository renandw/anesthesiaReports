import Foundation

final class TokenManager {
    static let shared = TokenManager(storage: AuthStorage())

    private let storage: AuthStorage
    private let baseURL = URL(string: "https://fichasanestesicas.bomsucessoserver.com")!

    init(storage: AuthStorage) {
        self.storage = storage
    }

    func accessToken() -> String? {
        storage.getAccessToken()
    }

    func refreshToken() -> String? {
        storage.getRefreshToken()
    }

    func saveTokens(access: String, refresh: String) {
        storage.save(accessToken: access, refreshToken: refresh)
    }

    func clear() {
        storage.clear()
    }

    func refresh() async throws -> AuthResponse {
        guard let refreshToken = refreshToken() else {
            throw AuthError.sessionExpired
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("/auth/refresh"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["refresh_token": refreshToken])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.network
        }

        if !(200...299).contains(http.statusCode) {
            throw AuthError.from(statusCode: http.statusCode, data: data)
        }

        let decoder = JSONDecoder()
        let tokens = try decoder.decode(AuthResponse.self, from: data)
        saveTokens(access: tokens.access_token, refresh: tokens.refresh_token)
        return tokens
    }
}
