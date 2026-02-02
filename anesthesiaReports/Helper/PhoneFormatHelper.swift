import Foundation

enum PhoneFormatHelper {
    static func digitsOnly(_ value: String) -> String {
        value.filter { $0.isNumber }
    }

    static func format(_ value: String) -> String {
        let digits = digitsOnly(value)
        if digits.count <= 2 {
            return digits
        }

        let ddd = String(digits.prefix(2))
        let rest = String(digits.dropFirst(2))

        if rest.count <= 4 {
            return "(\(ddd)) \(rest)"
        }

        if rest.count <= 8 {
            let first = String(rest.prefix(4))
            let second = String(rest.dropFirst(4))
            return "(\(ddd)) \(first)-\(second)"
        }

        let first = String(rest.prefix(5))
        let second = String(rest.dropFirst(5).prefix(4))
        return "(\(ddd)) \(first)-\(second)"
    }
}
