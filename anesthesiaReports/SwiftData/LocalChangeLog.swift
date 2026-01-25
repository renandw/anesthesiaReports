//
//  LocalChangeLog.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 25/01/26.
//


import Foundation
import SwiftData

@Model
final class LocalChangeLog {

    @Attribute(.unique)
    var operationId: UUID

    /// Nome da entidade (ex: "Patient", "Surgery")
    var entity: String

    /// ID da entidade afetada
    var entityId: UUID

    /// create | update | delete
    var operation: String

    /// Snapshot mínimo necessário para replay
    var payload: Data

    /// Quando a intenção foi criada
    var createdAt: Date

    init(
        operationId: UUID = UUID(),
        entity: String,
        entityId: UUID,
        operation: String,
        payload: Data,
        createdAt: Date = Date()
    ) {
        self.operationId = operationId
        self.entity = entity
        self.entityId = entityId
        self.operation = operation
        self.payload = payload
        self.createdAt = createdAt
    }
}
