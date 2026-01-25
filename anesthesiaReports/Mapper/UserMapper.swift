//
//  UserMapper.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 24/01/26.
//

extension User {
    /// Criação (quando não existe User local)
    static func from(dto: UserDTO) -> User {
        User(
            userId: dto.user_id,
            name: dto.user_name,
            emailAddress: dto.email,
            crm: dto.crm_number_uf,
            rqe: dto.rqe,
            active: dto.active,
            isDeleted: dto.is_deleted,
            createdAt: dto.created_at,
            updatedAt: dto.updated_at,
            statusChangedAt: dto.status_changed_at
        )
    }

    /// Atualização (quando o User já existe)
    func update(from dto: UserDTO) {
        name = dto.user_name
        emailAddress = dto.email
        crm = dto.crm_number_uf
        rqe = dto.rqe
        active = dto.active
        isDeleted = dto.is_deleted
        updatedAt = dto.updated_at
        statusChangedAt = dto.status_changed_at
    }
}
