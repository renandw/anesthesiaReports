//
//  SocialDomain.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 11/02/26.
//

enum SocialAndEnvironmentCategory: String {
    case environment
    case funcionalcapacity
    case alcohol
    case tobacco
    case drugs
}

enum FunctionalCapacityCode: String, Codable, CaseIterable, DomainCode {
    case independent      // >10 METs
    case moderate         // 4–10 METs
    case poor             // <4 METs
    case custom
    
    var displayName: String {
        switch self {
        case .independent:       "> 10 METs"
        case .moderate:         "4-10 METs"
        case .poor:             "< 4 METs"
        case .custom:           "Outros"
        }
    }
    static var customCase: Self { .custom }
}

enum SmokingCode: String, Codable, CaseIterable, DomainCode {
    case former
    case current
    case custom
    
    var displayName: String {
        switch self {
        case .former:           "Passado tabagista"
        case .current:          "Tabagista"
        case .custom:           "Outros"
        }
    }
    
    static var customCase: Self { .custom }
}

enum AlcoholCode: String, Codable, CaseIterable, DomainCode {
    case social
    case chronic
    case dependence
    case custom
    
    var displayName: String {
        switch self {
        case .social:           "Consumo Social"
        case .chronic:          "Consumo Crónico"
        case .dependence:       "Alcoóltra"
        case .custom:           "Outros"
        }
    }
    static var customCase: Self { .custom }
}


enum IllicitDrugCode: String, Codable, CaseIterable, DomainCode {
    case cocaine
    case marijuana
    case crack
    case amphetamine
    case opioid
    case custom
    
    var displayName: String {
        switch self {
        case .cocaine:           "Cocaina"
        case .marijuana:         "Maconha"
        case .crack:            "Crack"
        case .amphetamine:      "Amfetaminas"
        case .opioid:           "Ópioides"
        case .custom:            "Outros"
        }
    }
    static var customCase: Self { .custom}
}

enum RespiratoryExposureCode: String, Codable, CaseIterable, DomainCode {
    case woodSmoke        // fogão a lenha
    case biomassFuel      // carvão, queima orgânica
    case moldHumidity     // mofo / casa úmida
    case pollution        // área urbana poluída
    case occupationalDust // poeira, grãos, serragem, cimento
    case custom

    var displayName: String {
        switch self {
        case .woodSmoke:        "Fumaça de fogão a lenha"
        case .biomassFuel:      "Queima de biomassa - carvão"
        case .moldHumidity:     "Ambiente com mofo e umidade"
        case .pollution:        "Poluição urbana intensa"
        case .occupationalDust: "Exposição ocupacional à poeira"
        case .custom:           "Outra"
        }
    }

    static var customCase: Self { .custom }
}
