//
//  APIErrorResponse.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 24/01/26.
//


import Foundation

struct APIErrorResponse: Codable {
    let error: APIErrorDetail
}

struct APIErrorDetail: Codable {
    let code: String
    let message: String
}

enum NetworkError: Error {
    case invalidResponse
    case noConnection
    case timeout
    case decodingFailed
}

enum AuthError: Error {
    // Sessão
    case sessionExpired        // sessão inválida, não destrutiva
    case notAuthenticated

    // Conta (definitivo)
    case userInactive
    case userDeleted

    // Login
    case invalidCredentials

    // Infra
    case serverError
    case networkError
    case unknown
}

extension AuthError {

    /// Mapeia erro do backend para AuthError sem ambiguidade
    static func from(
        _ apiError: APIErrorResponse?,
        statusCode: Int
    ) -> AuthError {

        // 401 sem body → sessão inválida (refresh já falhou)
        guard let code = apiError?.error.code else {
            return statusCode == 401
                ? .sessionExpired
                : .serverError
        }

        switch code {

        // 🔐 Sessão (não destrutivo)
        case "TOKEN_INVALID", "TOKEN_EXPIRED":
            return .sessionExpired

        // 👤 Conta
        case "USER_INACTIVE":
            return .userInactive

        case "USER_DELETED":
            return .userDeleted

        // 🔑 Login
        case "INVALID_CREDENTIALS":
            return .invalidCredentials

        // 🧨 Backend
        default:
            return .unknown
        }
    }
}
