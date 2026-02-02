import Foundation

enum NameFormatHelper {
    static let lowercaseParticles: Set<String> = ["de", "da", "do", "das", "dos", "e"]

    static func normalizeTitleCase(_ value: String, lowercaseWords: Set<String> = lowercaseParticles) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        let normalized = parts.map { part -> String in
            let lower = part.lowercased()
            if lowercaseWords.contains(lower) {
                return lower
            }
            return lower.prefix(1).uppercased() + lower.dropFirst()
        }

        return normalized.joined(separator: " ")
    }

    static func hasAtLeastTwoWords(_ value: String) -> Bool {
        let parts = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return parts.count >= 2
    }
}
