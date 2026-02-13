//
//  NVPODomain.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 11/02/26.
//

enum NVPOCategory: String {
    case nvpo
}

enum ApfelScoreCode: String, Codable, CaseIterable, DomainCode {
    case tobaccoUse
    case femaleSex
    case historyPONV
    case historyMotionSickness
    case postoperativeOpioids
    case custom
    
    var displayName: String {
        switch self {
            // Substâncias
        case .femaleSex:                "Feminino"
        case .tobaccoUse:               "Tabagismo"
        case .historyPONV:              "História de NVPO"
        case .historyMotionSickness:    "Cinetose"
        case .postoperativeOpioids:     "Uso de opióide"
        case .custom:                   "Outra"
        }
    }
    var reportDisplayName: String {
        switch self {
            // Substâncias
        case .femaleSex:                "sexo feminino"
        case .tobaccoUse:               "hábito de tabagismo"
        case .historyPONV:              "história prévia de NVPO"
        case .historyMotionSickness:    "condição de cinetose"
        case .postoperativeOpioids:     "uso de opióides no período perioperatório"
        case .custom:                   "outra condição"
        }
    }
    static var customCase: Self { .custom }
}
