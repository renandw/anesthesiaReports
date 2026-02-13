//
//  PreanesthesiaItemDomain.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 10/02/26.
//


enum AirWayCategory: String {
    case mallampati
    case predictors
}

enum MallampatiCode: String, CaseIterable, DomainCode {
    case i
    case ii
    case iii
    case iv
    case custom
    
    var displayName: String {
        switch self {
        case .i: return "I"
        case .ii: return "II"
        case .iii: return "III"
        case .iv: return "IV"
        case .custom: return "Outros"
        }
    }
    static var customCase: MallampatiCode { .custom }
}

enum PredictorsAirWayCode: String, CaseIterable, DomainCode {
    case teethless
    case facialhair
    case shortneck
    case largeneck
    case smalloralopening
    case facialdeformation
    case custom
    
    var displayName: String {
        switch self {
        case .teethless: return "Sem dentes"
        case .facialhair: return "Pelos faciais"
        case .shortneck: return "Curto pescoço"
        case .largeneck: return "Pescoço largo"
        case .smalloralopening: return "Abertura oral pequena"
        case .facialdeformation: return "Deformação facial"
        case .custom: return "Outros"
        }
    }
    static var customCase: PredictorsAirWayCode { .custom }
}






