import Foundation

struct AuthAPI {

    private let client: HTTPClient

    init(client: HTTPClient = .shared) {
        self.client = client
    }

    // MARK: - Login

    func login(email: String, password: String) async throws -> AuthResponse {
        try await client.request(
            path: "/auth/login",
            method: "POST",
            body: [
                "email": email,
                "password": password
            ],
            requiresAuth: false
        )
    }

    // MARK: - Register

    func register(_ input: RegisterInput) async throws {
        _ = try await client.request(
            path: "/auth/register",
            method: "POST",
            body: input,
            requiresAuth: false
        ) as EmptyResponse
    }

}

// MARK: - DTOs
