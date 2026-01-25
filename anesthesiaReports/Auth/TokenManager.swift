import Foundation

final class TokenManager {

    static let shared = TokenManager()

    private init() {}

    // MARK: - Accessors

    func accessToken() async throws -> String {
        if let token = loadAccessToken(),
           !isExpired(token: token) {
            return token
        }

        // token expirado → tentar refresh
        return try await refreshAccessToken()
    }

    // MARK: - Refresh

    private func refreshAccessToken() async throws -> String {
        let refreshToken = try loadRefreshTokenOrThrow()

        let response = try await AuthAPI.refresh(
            refreshToken: refreshToken
        )

        saveTokens(
            accessToken: response.access_token,
            refreshToken: response.refresh_token
        )

        return response.access_token
    }

    // MARK: - Storage (Keychain)

    func saveTokens(accessToken: String, refreshToken: String) {
        // salvar no Keychain
    }

    func clearTokens() {
        // remover do Keychain
    }

    private func loadAccessToken() -> String? {
        // buscar no Keychain
        nil
    }

    private func loadRefreshTokenOrThrow() throws -> String {
        // buscar refresh token ou lançar erro de sessão
        throw AuthError.notAuthenticated
    }

    // MARK: - Helpers

    private func isExpired(token: String) -> Bool {
        // decode do JWT (exp)
        false
    }
}