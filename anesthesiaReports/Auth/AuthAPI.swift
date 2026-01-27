import Foundation

struct AuthAPI {

    private let baseURL = URL(string: "https://fichasanestesicas.bomsucessoserver.com")!

    // MARK: - Login

    func login(email: String, password: String) async throws -> AuthResponse {
        try await request(
            path: "/auth/login",
            body: [
                "email": email,
                "password": password
            ]
        )
    }

    // MARK: - Register

    func register(_ input: RegisterInput) async throws {
        _ = try await request(
            path: "/auth/register",
            body: input
        ) as EmptyResponse
    }

    // MARK: - Refresh

    func refresh(refreshToken: String) async throws -> AuthResponse {
        try await request(
            path: "/auth/refresh",
            body: [
                "refresh_token": refreshToken
            ]
        )
    }

    // MARK: - Generic request

    private func request<T: Decodable, B: Encodable>(
        path: String,
        body: B
    ) async throws -> T {

        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.network
        }

        if !(200...299).contains(http.statusCode) {
            throw AuthError.from(statusCode: http.statusCode, data: data)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - DTOs

