//
//  HTTPClient.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 25/01/26.
//

import Foundation

final class HTTPClient {

    static let shared = HTTPClient()
    private init() {}

    // MARK: - Public API

    func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        try await send(request, retryOnAuthError: true)
    }

    func sendNoContent(_ request: URLRequest) async throws {
        try await sendNoContent(request, retryOnAuthError: true)
    }

    // MARK: - Core

    private func send<T: Decodable>(
        _ request: URLRequest,
        retryOnAuthError: Bool
    ) async throws -> T {

        let requestWithAuth = try await authorizedRequest(from: request)
        let (data, response) = try await URLSession.shared.data(for: requestWithAuth)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        // sucesso
        if (200...299).contains(http.statusCode) {
            return try JSONDecoder.backend.decode(T.self, from: data)
        }

        // tenta refresh uma única vez
        if http.statusCode == 401, retryOnAuthError {
            do {
                try await TokenManager.shared.forceRefresh()
                return try await send(request, retryOnAuthError: false)
            } catch {
                throw AuthError.sessionExpired
            }
        }

        // erro padronizado do backend
        let apiError = try? JSONDecoder.backend.decode(
            APIErrorResponse.self,
            from: data
        )

        throw AuthError.from(apiError, statusCode: http.statusCode)
    }

    private func sendNoContent(
        _ request: URLRequest,
        retryOnAuthError: Bool
    ) async throws {

        let requestWithAuth = try await authorizedRequest(from: request)
        let (_, response) = try await URLSession.shared.data(for: requestWithAuth)

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if (200...299).contains(http.statusCode) {
            return
        }

        if http.statusCode == 401, retryOnAuthError {
            do {
                try await TokenManager.shared.forceRefresh()
                return try await sendNoContent(request, retryOnAuthError: false)
            } catch {
                throw AuthError.sessionExpired
            }
        }

        throw AuthError.from(nil, statusCode: http.statusCode)
    }

    // MARK: - Authorization

    private func authorizedRequest(from request: URLRequest) async throws -> URLRequest {
        var request = request

        // Endpoints que NÃO usam Authorization
        if isPublicEndpoint(request.url) {
            return request
        }

        let token = try await TokenManager.shared.validAccessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        return request
    }

    private func isPublicEndpoint(_ url: URL?) -> Bool {
        guard let path = url?.path else { return false }

        return path.hasSuffix("/auth/login")
            || path.hasSuffix("/auth/register")
            || path.hasSuffix("/auth/refresh")
    }
}
