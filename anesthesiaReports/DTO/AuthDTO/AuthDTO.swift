import Foundation


import Foundation

// MARK: - Auth

struct AuthResponse: Decodable {
    let access_token: String
    let refresh_token: String
    let expires_in: String
}

// MARK: - Register

struct RegisterInput: Encodable {
    let user_name: String
    let email: String
    let password: String
    let crm_number_uf: String
    let rqe: String?
    let phone: String
    let company: [String]
}

// MARK: - Empty

struct EmptyResponse: Decodable {}
