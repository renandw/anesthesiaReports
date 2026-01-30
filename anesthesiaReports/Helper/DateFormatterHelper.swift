import Foundation

enum DateFormatterHelper {
    static func format(
        _ date: Date,
        dateStyle: DateFormatter.Style = .short,
        timeStyle: DateFormatter.Style = .none,
        locale: Locale = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.locale = locale
        return formatter.string(from: date)
    }

    static func formatISODate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func normalizeISODateString(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 10 {
            return String(trimmed.prefix(10))
        }
        return trimmed
    }
    
    static func parseISODate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter.date(from: String(trimmed.prefix(10)))
    }

}
