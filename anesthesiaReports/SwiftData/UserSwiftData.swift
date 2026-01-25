//
//  UserSwiftData.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 24/01/26.
//
import Foundation
import SwiftData

@Model
final class User {

    @Attribute(.unique) var userId: String

    var name: String
    var emailAddress: String
    var crm: String
    var rqe: String?

    var active: Bool
    var isDeleted: Bool

    var createdAt: Date
    var updatedAt: Date
    var statusChangedAt: Date

    init(
        userId: String,
        name: String,
        emailAddress: String,
        crm: String,
        rqe: String? = nil,
        active: Bool,
        isDeleted: Bool,
        createdAt: Date,
        updatedAt: Date,
        statusChangedAt: Date
    ) {
        self.userId = userId
        self.name = name
        self.emailAddress = emailAddress
        self.crm = crm
        self.rqe = rqe
        self.active = active
        self.isDeleted = isDeleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.statusChangedAt = statusChangedAt
    }
}



