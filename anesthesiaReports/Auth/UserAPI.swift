import Foundation

struct UserAPI {

    private let baseURL = URL(string: "https://fichasanestesicas.bomsucessoserver.com")!

    // MARK: - GET /users/me (usado agora)

    func getMe(accessToken: String) async throws -> UserDTO {
        let request = authorizedRequest(
            path: "/users/me",
            method: "GET",
            accessToken: accessToken
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(GetMeResponse.self, from: data)
        return decoded.user
    }

    // MARK: - PATCH /users/me (não usado ainda)

    func updateMe(
        accessToken: String,
        payload: UpdateUserInput
    ) async throws -> UserDTO {
        var request = authorizedRequest(
            path: "/users/me",
            method: "PATCH",
            accessToken: accessToken
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(UpdateUserResponse.self, from: data)
        return decoded.user
    }

    // MARK: - DELETE /users/me (não usado ainda)

    func deleteMe(accessToken: String) async throws {
        let request = authorizedRequest(
            path: "/users/me",
            method: "DELETE",
            accessToken: accessToken
        )

        let (_, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: nil)
    }

    // MARK: - GET /users/related

    func getRelatedUsers(
        accessToken: String,
        company: String? = nil,
        search: String? = nil
    ) async throws -> [RelatedUserDTO] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("/users/related"),
            resolvingAgainstBaseURL: false
        )
        var items: [URLQueryItem] = []
        if let company, !company.isEmpty {
            items.append(URLQueryItem(name: "company", value: company))
        }
        if let search, !search.isEmpty {
            items.append(URLQueryItem(name: "search", value: search))
        }
        if !items.isEmpty {
            components?.queryItems = items
        }

        let url = components?.url ?? baseURL.appendingPathComponent("/users/related")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RelatedUsersResponse.self, from: data)
        return decoded.users
    }

    // MARK: - Helpers

    private func authorizedRequest(
        path: String,
        method: String,
        accessToken: String
    ) -> URLRequest {
        var request = URLRequest(
            url: baseURL.appendingPathComponent(path)
        )
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(
            "Bearer \(accessToken)",
            forHTTPHeaderField: "Authorization"
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func validate(response: URLResponse, data: Data?) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.network
        }

        if !(200...299).contains(http.statusCode) {
            throw AuthError.from(
                statusCode: http.statusCode,
                data: data ?? Data()
            )
        }
    }
}
