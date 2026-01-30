//
//  CNSFormatter.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 29/01/26.
//

public extension String {
    func cnsFormatted(expectedLength: Int = 15, digitsOnly: Bool = true) -> String {
        let digits = digitsOnly ? filter(\.isNumber) : self
        guard digits.count == expectedLength else { return self }

        let groups = [
            digits.prefix(3),
            digits.dropFirst(3).prefix(4),
            digits.dropFirst(7).prefix(4),
            digits.suffix(4)
        ]

        return groups.map(String.init).joined(separator: " ")
    }
}

enum numberCnsContext {
    case needed
    case notNeeded
}
