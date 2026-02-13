//
//  LabsAndImage.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 12/02/26.
//

enum LabsAndImageCategory: String, CaseIterable {
    case labs
    case ecg
    case chestxray
    case eco
    case veinusg
    case custom

    var displayName: String {
        switch self {
        case .labs: return "Laboratório"
        case .ecg: return "Eletrocardiograma"
        case .chestxray: return "Radiografia de Tórax"
        case .eco: return "Ecocardiograma"
        case .veinusg: return "Ultrassonografia Venosa Profunda"
        case .custom: return "Outra"
        }
    }
}

enum LabsCode: String, Codable, CaseIterable, DomainCode {
    case hb
    case ht
    case plaq
    case urea
    case creatinine
    case sodium
    case potassium
    case rni
    case glucose
    case custom

    var displayName: String {
        switch self {
        case .hb: return "Hemoglobina"
        case .ht: return "Hematócrito"
        case .plaq: return "Plaquetas"
        case .urea: return "Uréia"
        case .creatinine: return "Creatinina"
        case .sodium: return "Sódio"
        case .potassium: return "Potássio"
        case .rni: return "RNI"
        case .glucose: return "Glicemia"
        case .custom: return "Outra"
        }
    }

    static var customCase: Self { .custom }
}

enum ChestXRayCode: String, CaseIterable, Codable, DomainCode {
    case normal
    case cardiomegaly
    case pulmonaryCongestion
    case infiltrate
    case pleuralEffusion
    case atelectasis
    case custom
    
    var displayName: String {
        switch self {
        case .normal:                "Normal"
        case .cardiomegaly:          "Cardiomegalia"
        case .pulmonaryCongestion:   "Congestão Pulmonar"
        case .infiltrate:            "Infiltração"
        case .pleuralEffusion:       "Euforia Pléura"
        case .atelectasis:           "Atelectasia Pulmonar"
        case .custom:                "Outra"
        }
    }
    static var customCase: Self { .custom }
}

enum ECGCode: String, CaseIterable, Codable, DomainCode {
    case normal
    case sinusRhythm
    case atrialFibrillation
    case bre
    case bavt
    case custom
    
    var displayName: String {
        switch self {
        case .normal:                "Normal"
        case .sinusRhythm:           "Ritmo Sinusoidal"
        case .atrialFibrillation:    "Fibrilação Atrial"
        case .bre:                   "Bloqueio de Ramo Esquerdo"
        case .bavt:                  "BAVT"
        case .custom:                "Outra"
        }
    }
    static var customCase: Self { .custom }
}

enum EchocardiogramCode: String, CaseIterable, Codable, DomainCode {
    case normal
    case mitralInsufficiency
    case aorticInsufficiency
    case mitralStenoses
    case aorticStenoses
    case lowFE
    case custom
    
    var displayName: String {
        switch self {
        case .normal:                "Normal"
        case .mitralInsufficiency:   "Insuficiência Mitral"
        case .aorticInsufficiency:   "Insuficiência Aórtica"
        case .mitralStenoses:        "Estenose Mitral"
        case .aorticStenoses:        "Estenose Aórtica"
        case .lowFE:                 "Fração de Ejeção Baixa"
        case .custom:                "Outra"
        }
    }
    static var customCase: Self { .custom }
}
