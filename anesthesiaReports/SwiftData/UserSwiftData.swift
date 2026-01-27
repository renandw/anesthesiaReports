import Foundation
import SwiftData


@Model
final class UserModel {
    @Attribute(.unique) var id: String
    var name: String
    var email: String
    var crm: String
    var rqe: String?
    var isActive: Bool

    // Metadados
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        name: String,
        email: String,
        crm: String,
        rqe: String?,
        isActive: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.crm = crm
        self.rqe = rqe
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
