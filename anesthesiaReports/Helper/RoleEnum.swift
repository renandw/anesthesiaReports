//
//  RoleEnum.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 27/01/26.
//
import Foundation

enum RoleEnum: Codable, Hashable, Identifiable {
    case user
    case admin
    case custom(String)
    
    var id: String { rawValue }
    
    var rawValue: String {
        switch self {
        case .user:
            return "user"
        case .admin:
            return "admin"
        case .custom(let value):
            return value
        }
    }

    var displayName: String {
        switch self {
        case .user:
            return "Usuário"
        case .admin:
            return "Administrador"
        case .custom(let value):
            return value
                .replacingOccurrences(of: "_", with: " ")
                .split(separator: " ")
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                .joined(separator: " ")
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "user":
            self = .user
        case "admin":
            self = .admin
        default:
            self = .custom(raw)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
