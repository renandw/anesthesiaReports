//
//  PatientRowView.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 29/01/26.
//
import SwiftUI

struct PatientRowView: View {
    
    let patient: PatientDTO
    let numberCnsContext: numberCnsContext
    let ageContext: AgeContext
    
    private func initials(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard !parts.isEmpty else { return "" }
        if parts.count == 1 {
            if let firstChar = parts[0].first {
                return String(firstChar).uppercased()
            } else {
                return ""
            }
        } else {
            let firstPart = parts.first!
            let lastPart = parts.last!
            let firstInitial = firstPart.first.map { String($0) } ?? ""
            let lastInitial = lastPart.first.map { String($0) } ?? ""
            return (firstInitial + lastInitial).uppercased()
        }
    }
    
    private var ageText: String {
        guard let birthDate = DateFormatterHelper.parseISODate(patient.dateOfBirth) else {
            return "—"
        }
        return ageContext.ageString(from: birthDate)
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(patient.sex.sexColor)
                        .frame(width: 40, height: 40)
                    Text(initials(from: patient.name))
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading) {
                    Text(patient.name)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack {
                        Text(patient.sex.sexStringDescription)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)

                        Text(DateFormatterHelper
                            .parseISODate(patient.dateOfBirth)
                            .map { DateFormatterHelper.format($0, dateStyle: .medium) }
                            ?? "")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)

                        Text(ageText)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }

                    if numberCnsContext == .needed {
                        HStack {
                            Text("CNS:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .bold()
                            Text(patient.cns.cnsFormatted(expectedLength: 15, digitsOnly: true))
                                .font(.caption)
                                .foregroundStyle(patient.cns == "000000000000000" ? .red : .secondary)
                                .bold()
                        }
                    }
                }
            }
            .cornerRadius(12)
        }
    }
}
