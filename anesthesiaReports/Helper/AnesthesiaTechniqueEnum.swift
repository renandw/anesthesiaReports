import Foundation

public enum AnesthesiaTechniqueCategory: String, CaseIterable, Codable {
    case general
    case spinal
    case block
    case sedation
    case local
    case endovenousBlock = "endovenous_block"

    var displayName: String {
        switch self {
        case .general: return "Anestesia Geral"
        case .spinal: return "Anestesia Espinhal"
        case .block: return "Bloqueio Periférico"
        case .sedation: return "Sedação"
        case .local: return "Local"
        case .endovenousBlock: return "Bloqueio Endovenoso"
        }
    }
}

public enum AnesthesiaTechniqueType: String, CaseIterable, Codable {
    case tiva
    case inhalatory
    case balanced
    case raquianesthesia
    case peridural
    case mmss
    case mmii
    case abdominal
    case thoracic
    case head
    case infiltrative
    case topical
    case upperLimb = "upper_limb"
    case lowerLimb = "lower_limb"

    var displayName: String {
        switch self {
        case .tiva: return "TIVA"
        case .inhalatory: return "Inalatória"
        case .balanced: return "Balanceada"
        case .raquianesthesia: return "Raquianestesia"
        case .peridural: return "Peridural"
        case .mmss: return "Membros Superiores"
        case .mmii: return "Membros Inferiores"
        case .abdominal: return "Parede Abdominal"
        case .thoracic: return "Parede Torácica"
        case .head: return "Cabeça"
        case .infiltrative: return "Infiltrativa"
        case .topical: return "Tópica"
        case .upperLimb: return "Membro Superior"
        case .lowerLimb: return "Membro Inferior"
        }
    }
}

public enum AnesthesiaTechniqueRegion: String, CaseIterable, Codable {
    case axilar
    case supraclavicular
    case interscalenica
    case infraclavicular
    case radial
    case ulnar
    case mediano
    case femoral
    case saphenous
    case sciaticGluteal = "sciatic_gluteal"
    case sciaticPopliteal = "sciatic_popliteal"
    case lateralCutaneous = "lateral_cutaneous"
    case pengg
    case tap
    case ilioinguinal
    case rectusSheath = "rectus_sheath"
    case quadratusLumborum = "quadratus_lumborum"
    case pecs1
    case pecs2
    case serratus
    case paravertebral
    case erectorSpinae = "erector_spinae"
    case infraorbital
    case mental
    case alveolar
    case supraorbital

    var displayName: String {
        switch self {
        case .axilar: return "Axilar"
        case .supraclavicular: return "Supraclavicular"
        case .interscalenica: return "Interscalênica"
        case .infraclavicular: return "Infraclavicular"
        case .radial: return "Radial"
        case .ulnar: return "Ulnar"
        case .mediano: return "Mediano"
        case .femoral: return "Femoral"
        case .saphenous: return "Safeno"
        case .sciaticGluteal: return "Ciático (glúteo)"
        case .sciaticPopliteal: return "Ciático (poplíteo)"
        case .lateralCutaneous: return "Cutâneo lateral"
        case .pengg: return "PENGG"
        case .tap: return "TAP"
        case .ilioinguinal: return "Ílioinguinal"
        case .rectusSheath: return "Bainha do reto"
        case .quadratusLumborum: return "Quadrado lombar"
        case .pecs1: return "PECS I"
        case .pecs2: return "PECS II"
        case .serratus: return "Serrátil"
        case .paravertebral: return "Paravertebral"
        case .erectorSpinae: return "Eretor da espinha"
        case .infraorbital: return "Infraorbital"
        case .mental: return "Mental"
        case .alveolar: return "Alveolar"
        case .supraorbital: return "Supraorbital"
        }
    }
}

public enum AnesthesiaTechniqueHelper {
    static func types(for category: AnesthesiaTechniqueCategory) -> [AnesthesiaTechniqueType] {
        switch category {
        case .general:
            return [.tiva, .inhalatory, .balanced]
        case .spinal:
            return [.raquianesthesia, .peridural]
        case .block:
            return [.mmss, .mmii, .abdominal, .thoracic, .head]
        case .sedation:
            return [.tiva, .inhalatory, .balanced]
        case .local:
            return [.infiltrative, .topical]
        case .endovenousBlock:
            return [.upperLimb, .lowerLimb]
        }
    }

    static func regions(for type: AnesthesiaTechniqueType) -> [AnesthesiaTechniqueRegion] {
        switch type {
        case .mmss:
            return [.axilar, .supraclavicular, .interscalenica, .infraclavicular, .radial, .ulnar, .mediano]
        case .mmii:
            return [.femoral, .saphenous, .sciaticGluteal, .sciaticPopliteal, .lateralCutaneous, .pengg]
        case .abdominal:
            return [.tap, .ilioinguinal, .rectusSheath, .quadratusLumborum]
        case .thoracic:
            return [.pecs1, .pecs2, .serratus, .paravertebral, .erectorSpinae]
        case .head:
            return [.infraorbital, .mental, .alveolar, .supraorbital]
        default:
            return []
        }
    }
}
