import Foundation

enum SurgeryType: String, Codable, CaseIterable, Identifiable {
    case insurance
    case sus

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .insurance:
            return "Convênio"
        case .sus:
            return "SUS"
        }
    }
}
