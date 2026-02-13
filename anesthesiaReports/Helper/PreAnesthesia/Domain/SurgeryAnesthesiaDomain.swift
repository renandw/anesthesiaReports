//
//  SurgeryAnesthesiaDomain.swift
//  anesthesiaReports
//
//  Created by Renan Wrobel on 11/02/26.
//

enum SurgeryHistoryCategory: String {
    case general
    case orthopedics
    case cardiac
    case neurosurgery
    case urology
    case gynecology
    case bucomaxillofacial
    case ophthalmology
    case headAndNeck
    case oncology
    case thorax
    case vascular
    case narcose
}

enum AnesthesiaHistoryCategory: String {
    case complications
}

enum GeneralSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case apendicectomy
    case colecistectomy
    case herniorrhaphy
    case hemorroidectomy
    case fistulectomy
    case lipomectomy
    case custom
    
    var displayName: String {
        switch self {
        case .apendicectomy:                   "Apendicectomia"
        case .colecistectomy:                  "Colecistectomia"
        case .herniorrhaphy:                   "Herniorrafia"
        case .hemorroidectomy:                 "Hemorroidectomia"
        case .fistulectomy:                    "Fistulectomia"
        case .lipomectomy:                    "Lipomectomia"
        case .custom:                        "Outra"
        }
    }
    static var customCase: GeneralSurgeryHistoryCode { .custom }
}

enum OrtopedicSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case arthroplasty
    case arthroscopy
    case osteossintesis
    case fasciotomy
    case carpo
    case fixation
    case custom
    
    var displayName: String {
        switch self {
        case .arthroplasty:                   "Artroplastia"
        case .arthroscopy:                  "Artroscopia"
        case .osteossintesis:                   "Osteossíntese"
        case .fasciotomy:                 "Fasciotomia"
        case .carpo:                    "Descompressão do capo"
        case .fixation:                    "Fixação externa"
        case .custom:                        "Outra"
        }
    }
    static var customCase: OrtopedicSurgeryHistoryCode { .custom }
}

enum CardiacSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case revasc
    case valveAortic
    case valveMitral
    case civ
    case cia
    case pca
    case custom
    
    var displayName: String {
        switch self {
        case .revasc:                   "Revascularização do miocárdio"
        case .valveAortic:                  "Troca valvúla aórtica"
        case .valveMitral:                   "Plastia da válvula mitral"
        case .civ:                 "Correção de CIV"
        case .cia:                    "Correção de CIA"
        case .pca:                    "Correção de PCA"
        case .custom:                        "Outra"
        }
    }
    static var customCase: CardiacSurgeryHistoryCode { .custom }
}

enum NeurologicSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case dve
    case dvp
    case tumor
    case aneurism
    case descompressive
    case subdural
    case custom
    
    var displayName: String {
        switch self {
        case .dve:                   "DVE"
        case .dvp:                  "DVP"
        case .tumor:                   "Exérese de tumor cerbral"
        case .aneurism:                 "Clipagem de aneurisma"
        case .descompressive:                    "Craniectomia descompressiva"
        case .subdural:                    "Drenagem de hematoma subdural"
        case .custom:                        "Outra"
        }
    }
    static var customCase: NeurologicSurgeryHistoryCode { .custom }
}

enum UrologicSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case postectomy
    case rtuProstate
    case radicalProstatectomy
    case nephrectomy
    case percutaneousNephrolithotomy
    case lithotripsy
    case cystectomy
    case bladderTumorResection
    case orchiectomy
    case custom

    var displayName: String {
        switch self {
        case .postectomy:                   "Postectomia"
        case .rtuProstate:                  "RTU de próstata"
        case .radicalProstatectomy:         "Prostatectomia radical"
        case .nephrectomy:                  "Nefrectomia"
        case .percutaneousNephrolithotomy:  "Nefrolitotomia percutânea"
        case .lithotripsy:                  "Litototripsia"
        case .cystectomy:                   "Cistectomia"
        case .bladderTumorResection:        "RTU de bexiga"
        case .orchiectomy:                  "Orquiectomia"
        case .custom:                       "Outra"
        }
    }

    static var customCase: UrologicSurgeryHistoryCode { .custom }
}

enum GynecologicSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case hysterectomy
    case myomectomy
    case oophorectomy
    case pelvicLaparoscopy
    case conization
    case custom

    var displayName: String {
        switch self {
        case .hysterectomy:              "Histerectomia"
        case .myomectomy:                "Miomectomia"
        case .oophorectomy:              "Anexectomia"
        case .pelvicLaparoscopy:         "Laparoscopia pélvica"
        case .conization:                "Conização"
        case .custom:                    "Outra"
        }
    }

    static var customCase: GynecologicSurgeryHistoryCode { .custom }
}

enum BucomaxillofacialSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case orthognathic
    case mandibularFracture
    case tmjSurgery
    case zhigomatic
    case custom

    var displayName: String {
        switch self {
        case .orthognathic:        "Cirurgia ortognática"
        case .mandibularFracture:  "Fratura de mandíbula"
        case .tmjSurgery:          "Cirurgia de ATM"
        case .zhigomatic:           "Fratura de zigomático"
        case .custom:              "Outra"
        }
    }

    static var customCase: BucomaxillofacialSurgeryHistoryCode { .custom }
}

enum OphthalmologicSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case cataract
    case glaucoma
    case vitrectomy
    case retinalDetachment
    case custom

    var displayName: String {
        switch self {
        case .cataract:            "Cirurgia de catarata"
        case .glaucoma:            "Cirurgia de glaucoma"
        case .vitrectomy:          "Vitrectomia"
        case .retinalDetachment:   "Descolamento de retina"
        case .custom:              "Outra"
        }
    }

    static var customCase: OphthalmologicSurgeryHistoryCode { .custom }
}

enum HeadAndNeckSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case laryngectomy
    case thyroidectomy
    case parotidectomy
    case neckDissection
    case custom

    var displayName: String {
        switch self {
        case .laryngectomy:    "Laringectomia"
        case .thyroidectomy:   "Tireoidectomia"
        case .parotidectomy:   "Parotidectomia"
        case .neckDissection:  "Esvaziamento cervical"
        case .custom:          "Outra"
        }
    }

    static var customCase: HeadAndNeckSurgeryHistoryCode { .custom }
}

enum OncologicSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case colectomy
    case gastrectomy
    case esophagectomy
    case mastectomy
    case lungResection
    case whipple
    case custom

    var displayName: String {
        switch self {
        case .colectomy:        "Colectomia"
        case .gastrectomy:      "Gastrectomia"
        case .esophagectomy:    "Esofagectomia"
        case .mastectomy:       "Mastectomia"
        case .lungResection:    "Lobectomia"
        case .whipple:          "Gastroduodenopancreatectomia"
        case .custom:           "Outra"
        }
    }

    static var customCase: OncologicSurgeryHistoryCode { .custom }
}

enum ThoracicSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case lobectomy
    case pneumonectomy
    case pleurodesis
    case thoracotomy
    case custom

    var displayName: String {
        switch self {
        case .lobectomy:     "Lobectomia"
        case .pneumonectomy: "Pneumonectomia"
        case .pleurodesis:   "Pleurodese"
        case .thoracotomy:   "Toracotomia prévia"
        case .custom:        "Outra"
        }
    }

    static var customCase: ThoracicSurgeryHistoryCode { .custom }
}

enum PlasticSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case abdominoplasty
    case breastImplant
    case reductionMammoplasty
    case skinGraft
    case debris
    case rhinplasty
    case custom

    var displayName: String {
        switch self {
        case .abdominoplasty:       "Abdominoplastia"
        case .breastImplant:        "Prótese mamária"
        case .reductionMammoplasty: "Mamoplastia redutora"
        case .skinGraft:            "Enxerto cutâneo"
        case .debris:               "Desbridamento"
        case .rhinplasty:           "Rinoplastia"
        case .custom:               "Outra"
        }
    }

    static var customCase: Self { .custom }
}

enum VascularSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case carotidEndarterectomy
    case aorticAneurysmRepair
    case peripheralBypass
    case varicoseVeinSurgery
    case custom

    var displayName: String {
        switch self {
        case .carotidEndarterectomy: "Endarterectomia de carótida"
        case .aorticAneurysmRepair:  "Correção de aneurisma de aorta"
        case .peripheralBypass:      "Ponte arterial periférica"
        case .varicoseVeinSurgery:   "Cirurgia de varizes"
        case .custom:                "Outra"
        }
    }

    static var customCase: Self { .custom }
}

enum NarcosisSurgeryHistoryCode: String, Codable, CaseIterable, DomainCode {
    case eda
    case colonoscopy
    case bronchoscopy
    case mrisedation
    case custom

    var displayName: String {
        switch self {
        case .eda: "Endoscopia Digestiva Alta"
        case .colonoscopy:  "Colonoscopia"
        case .bronchoscopy:      "Broncoscopia"
        case .mrisedation:   "Sedação para TC/RNM"
        case .custom:                "Outra"
        }
    }

    static var customCase: Self { .custom }
}

enum AnesthesiaComplicationsHistoryCode: String, Codable, CaseIterable, DomainCode {
   case nausea
   case laryngospasm
   case broncospasm
   case cardiacArrest
   case neuropraxia
   case allergicReaction
   case spinalHeadache
   case difficultIntubation
   case shishivering
   case bronchoaspiration
   case custom
   
   var displayName: String {
       switch self {
       case .nausea:                       "Náusea e Vômitos"
       case .laryngospasm:                 "Laringoespasmo"
       case .broncospasm:                  "Broncoespasmo"
       case .cardiacArrest:                "Parada Cardiorespiratória"
       case .neuropraxia:                  "Neuropraxia"
       case .allergicReaction:             "Reação Alérgica"
       case .spinalHeadache:               "Cefaléia pós punção de duramater"
       case .difficultIntubation:          "Intubação Difícil"
       case .shishivering:                 "Tremores"
       case .bronchoaspiration:            "Broncoaspiração"
       case .custom:                       "Outros"
       }
   }
    static var customCase: Self { .custom }
}
