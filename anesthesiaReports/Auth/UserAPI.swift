import Foundation

struct UserAPI {

    private let client: HTTPClient

    init(client: HTTPClient = .shared) {
        self.client = client
    }

    // MARK: - GET /users/me (usado agora)

    func getMe() async throws -> UserDTO {
        let decoded: GetMeResponse = try await client.request(
            path: "/users/me",
            method: "GET",
            requiresAuth: true
        )
        return decoded.user
    }

    // MARK: - PATCH /users/me (não usado ainda)

    func updateMe(payload: UpdateUserInput) async throws -> UserDTO {
        let decoded: UpdateUserResponse = try await client.request(
            path: "/users/me",
            method: "PATCH",
            body: payload,
            requiresAuth: true
        )
        return decoded.user
    }

    // MARK: - DELETE /users/me (não usado ainda)

    func deleteMe() async throws {
        _ = try await client.request(
            path: "/users/me",
            method: "DELETE",
            requiresAuth: true
        ) as EmptyResponse
    }

    // MARK: - GET /users/related

    func getRelatedUsers(
        company: String? = nil,
        search: String? = nil
    ) async throws -> [RelatedUserDTO] {
        var items: [URLQueryItem] = []
        if let company, !company.isEmpty {
            items.append(URLQueryItem(name: "company", value: company))
        }
        if let search, !search.isEmpty {
            items.append(URLQueryItem(name: "search", value: search))
        }

        let decoded: RelatedUsersResponse = try await client.request(
            path: "/users/related",
            method: "GET",
            queryItems: items,
            requiresAuth: true
        )
        return decoded.users
    }
}
