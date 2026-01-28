import Foundation

final class HTTPClient {
    static let shared = HTTPClient(tokenManager: .shared)

    private let tokenManager: TokenManager
    private let baseURL = URL(string: "https://fichasanestesicas.bomsucessoserver.com")!

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
    }

    func request<T: Decodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        try await request(
            path: path,
            method: method,
            bodyData: nil,
            queryItems: queryItems,
            requiresAuth: requiresAuth,
            didRetry: false
        )
    }

    func request<T: Decodable, B: Encodable>(
        path: String,
        method: String,
        body: B,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = false
    ) async throws -> T {
        try await request(
            path: path,
            method: method,
            bodyData: try JSONEncoder().encode(body),
            queryItems: queryItems,
            requiresAuth: requiresAuth,
            didRetry: false
        )
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        bodyData: Data?,
        queryItems: [URLQueryItem]?,
        requiresAuth: Bool,
        didRetry: Bool
    ) async throws -> T {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems?.isEmpty == false ? queryItems : nil

        let url = components?.url ?? baseURL.appendingPathComponent(path)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = bodyData

        if requiresAuth {
            guard let token = tokenManager.accessToken() else {
                throw AuthError.sessionExpired
            }
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.network
        }

        if (200...299).contains(http.statusCode) {
            if data.isEmpty, let empty = EmptyResponse() as? T {
                return empty
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        }

        let authError = AuthError.from(statusCode: http.statusCode, data: data)
        if requiresAuth, authError.isRefreshable, !didRetry {
            _ = try await tokenManager.refresh()
            return try await request(
                path: path,
                method: method,
                bodyData: bodyData,
                queryItems: queryItems,
                requiresAuth: requiresAuth,
                didRetry: true
            )
        }

        throw authError
    }
}
