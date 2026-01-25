import Foundation

// MARK: - UserResponse DTO
// Espelha exatamente o retorno de GET /users/me

struct UserDTO: Codable {

    let user_id: String
    let user_name: String
    let email: String
    let crm_number_uf: String
    let rqe: String?

    let active: Bool
    let is_deleted: Bool

    let created_at: Date
    let updated_at: Date
    let status_changed_at: Date
}
