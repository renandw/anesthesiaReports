//
//  AuthAPI.swift
//  anesthesiaReports
//

import Foundation

final class AuthAPI {

    private static let baseURL = AppEnvironment.baseURL

    // MARK: - Login (público)

    static func login(
        email: String,
        password: String
    ) async throws -> LoginResponse {

        var request = URLRequest(
            url: baseURL.appendingPathComponent("auth/login")
        )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(
            LoginRequest(email: email, password: password)
        )

        return try await HTTPClient.shared.send(request)
    }

    // MARK: - Register (público)

    static func register(
        requestBody: RegisterRequest
    ) async throws -> RegisterResponse {

        var request = URLRequest(
            url: baseURL.appendingPathComponent("auth/register")
        )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(requestBody)

        return try await HTTPClient.shared.send(request)
    }

    // MARK: - Refresh (público, sem Authorization)

    static func refresh(
        refreshToken: String
    ) async throws -> RefreshResponse {

        var request = URLRequest(
            url: baseURL.appendingPathComponent("auth/refresh")
        )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(
            RefreshRequest(refresh_token: refreshToken)
        )

        return try await HTTPClient.shared.send(request)
    }

    // MARK: - User State (privado)

    static func fetchMe() async throws -> UserDTO {

        let request = URLRequest(
            url: baseURL.appendingPathComponent("users/me")
        )

        let response: MeResponse = try await HTTPClient.shared.send(request)
        return response.user
    }

    // MARK: - Logout (privado)

    static func logout() async throws {

        var request = URLRequest(
            url: baseURL.appendingPathComponent("auth/logout")
        )
        request.httpMethod = "POST"

        try await HTTPClient.shared.sendNoContent(request)
    }
}
