import Foundation

enum Company: Codable, Hashable, Identifiable {
    case known(KnownCompany)
    case custom(String)

    var id: String { rawValue }

    var rawValue: String {
        switch self {
        case .known(let company):
            return company.rawValue
        case .custom(let value):
            return value
        }
    }

    var displayName: String {
        switch self {
        case .known(let company):
            return company.displayName
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
        if let known = KnownCompany(rawValue: raw) {
            self = .known(known)
        } else {
            self = .custom(raw)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static func fromInput(_ value: String) -> Company {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.lowercased()
        if let known = KnownCompany(rawValue: normalized) {
            return .known(known)
        }
        return .custom(normalized)
    }
}

enum KnownCompany: String, CaseIterable, Codable, Identifiable {
    case cma
    case clian

    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .cma:
            return "CMA"
        case .clian:
            return "Clian"
        }
    }
}

extension Array where Element == Company {
    var displayJoined: String {
        map { $0.displayName }.joined(separator: ", ")
    }

    var rawJoined: String {
        map { $0.rawValue }.joined(separator: ", ")
    }

    static func parse(from text: String) -> [Company] {
        let items = text
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var seen = Set<String>()
        var result: [Company] = []
        for item in items {
            let company = Company.fromInput(item)
            let key = company.rawValue.lowercased()
            if seen.contains(key) { continue }
            seen.insert(key)
            result.append(company)
        }
        return result
    }
}
