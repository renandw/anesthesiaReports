import SwiftUI

enum SurgeryPermission: String, Codable, Hashable, Identifiable {
    case read
    case pre_editor
    case ane_editor
    case srpa_editor
    case full_editor
    case owner
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .read:
            return "Leitura"
        case .pre_editor:
            return "Pré‑anestesia"
        case .ane_editor:
            return "Anestesia"
        case .srpa_editor:
            return "SRPA"
        case .full_editor:
            return "Editor completo"
        case .owner:
            return "Criador"
        case .unknown:
            return "Sem permissão"
        }
    }

    var iconName: String {
        switch self {
        case .read:
            return "eye"
        case .pre_editor:
            return "stethoscope"
        case .ane_editor:
            return "syringe"
        case .srpa_editor:
            return "bed.double"
        case .full_editor:
            return "pencil"
        case .owner:
            return "crown.fill"
        case .unknown:
            return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .read:
            return .blue
        case .pre_editor:
            return .teal
        case .ane_editor:
            return .purple
        case .srpa_editor:
            return .indigo
        case .full_editor:
            return .green
        case .owner:
            return .orange
        case .unknown:
            return .secondary
        }
    }
}
