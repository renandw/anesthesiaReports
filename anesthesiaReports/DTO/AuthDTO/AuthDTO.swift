import Foundation
//
//  AuthDTO.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 24/01/26.
//

// MARK: - Login
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let access_token: String
    let refresh_token: String
}

// MARK: - Register
struct RegisterRequest: Codable {
    let user_name: String
    let email: String
    let password: String
    let crm_number_uf: String
    let rqe: String?
}

struct RegisterUserDTO: Codable {
    let user_id: String
    let user_name: String
    let email: String
    let crm_number_uf: String
    let rqe: String?
    let created_at: Date
}

struct RegisterResponse: Codable {
    let user: RegisterUserDTO
}

// MARK: - Refresh
struct RefreshRequest: Codable {
    let refresh_token: String
}

struct RefreshResponse: Codable {
    let access_token: String
    let refresh_token: String
}

struct MeResponse: Codable {
    let user: UserDTO
}
