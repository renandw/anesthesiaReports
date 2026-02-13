//
//  MedicationsDomain.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 13/02/26.
//

enum MedicationsCategory: String, CaseIterable {
    case allergy
    case dailymeds

    var displayName: String {
        switch self {
        case .allergy: "Alergias"
        case .dailymeds: "Medicamentos Diários"
        }
    }
}
