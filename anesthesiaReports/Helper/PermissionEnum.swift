import SwiftUI

enum PatientPermission: String, Codable, Hashable, Identifiable {
    case read
    case write
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .read:
            return "Leitura"
        case .write:
            return "Escrita"
        case .unknown:
            return "Sem Autorização"
        }
    }

    var iconName: String {
        switch self {
        case .read:
            return "eye"
        case .write:
            return "pencil"
        case .unknown:
            return "nosign"
        }
    }

    var color: Color {
        switch self {
        case .read:
            return .blue
        case .write:
            return .green
        case .unknown:
            return .secondary
        }
    }
}

extension PatientRole {
    var displayName: String {
        switch self {
        case .owner:
            return "Criador"
        case .editor:
            return "Editor"
        case .shared:
            return "Compartilhado"
        case .unknown:
            return "Sem Papel"
        }
    }

    var iconName: String {
        switch self {
        case .owner:
            return "crown.fill"
        case .editor:
            return "pencil.circle.fill"
        case .shared:
            return "person.2.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .owner:
            return .orange
        case .editor:
            return .blue
        case .shared:
            return .secondary
        case .unknown:
            return .secondary
        }
    }
}
