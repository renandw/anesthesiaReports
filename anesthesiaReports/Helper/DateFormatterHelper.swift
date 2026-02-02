import Foundation

enum DateFormatterHelper {
    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static var cache: [String: DateFormatter] = [:]

    static func format(
        _ date: Date,
        dateStyle: DateFormatter.Style = .short,
        timeStyle: DateFormatter.Style = .none,
        locale: Locale = .current
    ) -> String {
        let key = "\(dateStyle.rawValue)|\(timeStyle.rawValue)|\(locale.identifier)"
        if let cached = cache[key] {
            return cached.string(from: date)
        }
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.locale = locale
        cache[key] = formatter
        return formatter.string(from: date)
    }

    static func formatISODate(_ date: Date) -> String {
        isoFormatter.string(from: date)
    }

    static func formatISODateString(
        _ value: String,
        dateStyle: DateFormatter.Style = .medium,
        locale: Locale = .current
    ) -> String {
        guard let date = parseISODate(value) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = dateStyle
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func normalizeISODateString(_ value: String) -> String {
        guard let parsed = parseISODate(value) else { return "" }
        return formatISODate(parsed)
    }
    
    static func parseISODate(_ value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = String(trimmed.prefix(10))
        guard isoFormatter.date(from: candidate) != nil else { return nil }
        return isoFormatter.date(from: candidate)
    }
}
