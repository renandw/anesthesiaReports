//
//  PhysicalExam.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 11/02/26.
//

enum PhysicalExamCategory: String, CaseIterable {
    case general
    case brain
    case heart
    case lungs
    case abdome
    case limbs
    
    var displayName: String {
        switch self {
        case .general: return "Geral"
        case .brain: return "Neurológico"
        case .heart: return "Cardiológico"
        case .lungs: return "Respiratório"
        case .abdome: return "Digestivo"
        case .limbs: return "Membros"
        }
    }
}

//enum GeneralCode: String, Codable, CaseIterable, DomainCode {
//    case goodGeneralCondition
//    case regularGeneralCondition
//    case poorGeneralCondition
//    case custom
//    
//    var displayName: String {
//        switch self {
//        case .goodGeneralCondition:    "Bom estado geral"
//        case .regularGeneralCondition: "Estado geral regular"
//        case .poorGeneralCondition:    "Mau estado geral"
//        case .custom:                   "Outros"
//        }
//    }
//    
//    var reportDisplayName: String {
//        switch self {
//        case .goodGeneralCondition:    "em bom estado geral"
//        case .regularGeneralCondition: "em estado geral regular"
//        case .poorGeneralCondition:    "em mau estado geral"
//        case .custom:                   "com outros detalhes"
//
//        }
//    }
//    
//    static var customCase: Self { .custom }
//}
//
//enum BrainCode: String, Codable, CaseIterable, DomainCode {
//    case consciousAndOriented
//    case disoriented
//    case torporous
//    case unresponsive
//    case custom
//    
//    var displayName: String {
//        switch self {
//        case .consciousAndOriented: "Consciente e orientado"
//        case .disoriented:          "Desorientado"
//        case .torporous:            "Torporoso"
//        case .unresponsive:         "Não responsivo"
//        case .custom:               "Outro achado neurológico"
//        }
//    }
//    
//    var reportDisplayName: String {
//        switch self {
//        case .consciousAndOriented: "consciente e orientado"
//        case .disoriented:          "desorientado"
//        case .torporous:            "torporoso"
//        case .unresponsive:         "não responsivo"
//        case .custom:               "com outro achado neurológico"
//        }
//    }
//    
//    static var customCase: Self { .custom }
//}
//
//enum HeartCode: String, Codable, CaseIterable, DomainCode {
//    case regularRhythmNoMurmur
//    case irregularRhythm
//    case custom
//    
//    var displayName: String {
//        switch self {
//        case .regularRhythmNoMurmur:   "Ritmo regular em dois tempos"
//        case .irregularRhythm:         "Ritmo irregular"
//        case .custom:                  "Outro achado cardiovascular"
//        }
//    }
//    
//    var reportDisplayName: String {
//        switch self {
//        case .regularRhythmNoMurmur:   "ritmo regular em dois tempos"
//        case .irregularRhythm:         "ritmo irregular"
//        case .custom:                  "com outro achado cardiovascular"
//        }
//    }
//    
//    static var customCase: Self { .custom }
//}
