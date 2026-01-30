import SwiftUI

enum Permission: String, Codable, Hashable, Identifiable {
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
