import Foundation

// MARK: - UserResponse DTO
// Espelha exatamente o retorno de GET /users/me

struct UserDTO: Decodable {
    let id: String
    let name: String
    let email: String
    let crm: String
    let rqe: String?
    let phone: String
    let company: [String]
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    let statusChangedAt: Date?
    let isDeleted: Bool?

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name = "user_name"
        case email
        case crm = "crm_number_uf"
        case rqe
        case phone
        case company
        case isActive = "active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case statusChangedAt = "status_changed_at"
        case isDeleted = "is_deleted"
    }
}

// MARK: - DTOs

struct GetMeResponse: Decodable {
    let user: UserDTO
}

struct UpdateUserResponse: Decodable {
    let user: UserDTO
}

struct UpdateUserInput: Encodable {
    let user_name: String?
    let email: String?
    let crm_number_uf: String?
    let rqe: String?
    let phone: String?
    let company: [String]?
}

// MARK: - Related users

struct RelatedUserDTO: Decodable, Identifiable {
    let id: String
    let name: String
    let crm: String
    let rqe: String?
    let company: [String]

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name = "user_name"
        case crm = "crm_number_uf"
        case rqe
        case company
    }
}

struct RelatedUsersResponse: Decodable {
    let users: [RelatedUserDTO]
}
