import Foundation

final class AuthAPI {

    private static let baseURL = URL(string: "http://localhost:7362")!

    // MARK: - Login

    static func login(
        email: String,
        password: String
    ) async throws -> LoginResponse {

        var request = URLRequest(
            url: baseURL.appendingPathComponent("/auth/login")
        )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(
            LoginRequest(email: email, password: password)
        )

        return try await send(request)
    }

    // MARK: - Register

    static func register(
        requestBody: RegisterRequest
    ) async throws -> RegisterResponse {

        var request = URLRequest(
            url: baseURL.appendingPathComponent("/auth/register")
        )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(requestBody)

        return try await send(request)
    }

    // MARK: - Refresh (não usa access token)

    static func refresh(
        refreshToken: String
    ) async throws -> RefreshResponse {

        var request = URLRequest(
            url: baseURL.appendingPathComponent("/auth/refresh")
        )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(
            RefreshRequest(refresh_token: refreshToken)
        )

        return try await send(request)
    }

    // MARK: - User State

    static func fetchMe() async throws -> UserDTO {

        let token = try await TokenManager.shared.accessToken()

        var request = URLRequest(
            url: baseURL.appendingPathComponent("/users/me")
        )
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return try await send(request)
    }

    // MARK: - Core HTTP

    private static func send<T: Decodable>(
        _ request: URLRequest
    ) async throws -> T {

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder.backend.decode(T.self, from: data)
        }

        // erro padronizado
        let apiError = try? JSONDecoder.backend.decode(
            APIErrorResponse.self,
            from: data
        )

        throw AuthError.from(apiError, statusCode: http.statusCode)
    }
}