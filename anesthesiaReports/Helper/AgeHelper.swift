//
//  AgeHelper.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 29/01/26.
//
import Foundation

import Foundation

enum AgeContext {
    case out
    case at(date: Date)

    /// Data de referência para cálculo da idade
    private var referenceDate: Date {
        switch self {
        case .out:
            return .now
        case .at(let date):
            return date
        }
    }

    /// Retorna a idade em anos (inteiro) com base no contexto
    func ageInYears(from birthDate: Date) -> Int {
        let years = Calendar.current
            .dateComponents([.year], from: birthDate, to: referenceDate)
            .year ?? 0
        return max(0, years)
    }

    /// Formata a idade de maneira compacta (snippet)
    /// - < 1 ano: "Xm Yd"
    /// - 1–11 anos: "Xa Ym"
    /// - >= 12 anos: "Xa"
    func ageString(from birthDate: Date) -> String {
        let calendar = Calendar.current
        let dob = birthDate
        let now = referenceDate

        let years = calendar.dateComponents([.year], from: dob, to: now).year ?? 0

        if years < 1 {
            // < 1 ano: meses e dias
            let monthsTotal = calendar.dateComponents([.month], from: dob, to: now).month ?? 0
            let months = max(0, monthsTotal)

            let dateAfterMonths = calendar.date(byAdding: .month, value: months, to: dob) ?? dob
            let days = max(
                0,
                calendar.dateComponents([.day], from: dateAfterMonths, to: now).day ?? 0
            )

            return "\(months)m \(days)d"

        } else if years < 12 {
            // 1–11 anos: anos e meses
            let dateAfterYears = calendar.date(byAdding: .year, value: years, to: dob) ?? dob
            let months = max(
                0,
                calendar.dateComponents([.month], from: dateAfterYears, to: now).month ?? 0
            )

            return "\(years)a \(months)m"

        } else {
            // >= 12 anos: anos
            return "\(years)a"
        }
    }

    /// Formata a idade de maneira longa (legível)
    func ageLongString(from birthDate: Date) -> String {
        let calendar = Calendar.current
        let dob = birthDate
        let now = referenceDate

        let years = calendar.dateComponents([.year], from: dob, to: now).year ?? 0

        if years < 1 {
            let monthsTotal = calendar.dateComponents([.month], from: dob, to: now).month ?? 0
            let months = max(0, monthsTotal)

            let dateAfterMonths = calendar.date(byAdding: .month, value: months, to: dob) ?? dob
            let days = max(
                0,
                calendar.dateComponents([.day], from: dateAfterMonths, to: now).day ?? 0
            )

            let monthText = months == 1 ? "mês" : "meses"
            let dayText = days == 1 ? "dia" : "dias"

            return "\(months) \(monthText) \(days) \(dayText)"

        } else if years < 12 {
            let dateAfterYears = calendar.date(byAdding: .year, value: years, to: dob) ?? dob
            let months = max(
                0,
                calendar.dateComponents([.month], from: dateAfterYears, to: now).month ?? 0
            )

            let yearText = years == 1 ? "ano" : "anos"
            let monthText = months == 1 ? "mês" : "meses"

            return "\(years) \(yearText) \(months) \(monthText)"

        } else {
            let yearText = years == 1 ? "ano" : "anos"
            return "\(years) \(yearText)"
        }
    }
}

//Exemplo de uso:


///AgeContext.out.ageString(from: patient.birthDate)
///AgeContext.at(date: surgeryDate).ageLongString(from: patient.birthDate)

//var ageAtSurgery: String {
//    guard
//        let patient,
//        let birthDate = DateFormatterHelper.parseISODate(patient.dateOfBirth)
//    else {
//        return "—"
//    }
//
//    return AgeContext.at(date: surgeryDate).ageString(from: birthDate)
//}
