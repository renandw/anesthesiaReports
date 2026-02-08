import SwiftUI

public enum ClearanceStatus: String, Codable, CaseIterable {
    case able
    case reevaluate
    case unable

    var availableItems: [any ClearanceItem] {
        switch self {
        case .able: return AbleRecommendation.allCases
        case .reevaluate: return ReevaluatePendency.allCases
        case .unable: return UnableReason.allCases
        }
    }

    var itemType: String {
        switch self {
        case .able: return "able_recommendation"
        case .reevaluate: return "reevaluate_pendency"
        case .unable: return "unable_reason"
        }
    }

    var displayName: String {
        switch self {
        case .able: return "Liberado"
        case .reevaluate: return "Liberado com ressalvas"
        case .unable: return "Não liberado"
        }
    }

    var reportDisplayName: String {
        switch self {
        case .able: return "liberado sem ressalvas"
        case .reevaluate: return "liberado com ressalvas"
        case .unable: return "contraindicado ao ato anestésico"
        }
    }

    var sectionTitle: String {
        switch self {
        case .able: return "Recomendações Perioperatórias"
        case .reevaluate: return "Pendências a Reavaliar"
        case .unable: return "Motivos da Contraindicação"
        }
    }

    var color: Color {
        switch self {
        case .able: return .green
        case .reevaluate: return .yellow
        case .unable: return .red
        }
    }

    var icon: String {
        switch self {
        case .able: return "checkmark.circle.fill"
        case .reevaluate: return "exclamationmark.circle.fill"
        case .unable: return "xmark.circle.fill"
        }
    }
}

protocol ClearanceItem: Codable, Hashable, CaseIterable {
    var displayName: String { get }
    var reportDisplayName: String { get }
    var rawValue: String { get }
}

public enum AbleRecommendation: String, ClearanceItem {
    case adaptedFasting
    case bronchodilatorsInOR

    var displayName: String {
        switch self {
        case .adaptedFasting: return "Jejum adaptado"
        case .bronchodilatorsInOR: return "Broncodilatadores no CC"
        }
    }

    var reportDisplayName: String {
        switch self {
        case .adaptedFasting: return "jejum conforme orientado em consulta"
        case .bronchodilatorsInOR: return "uso de broncodilatadores em centro cirúrgico"
        }
    }
}

public enum ReevaluatePendency: String, ClearanceItem {
    case icuBedRequired
    case cardiacEnzymes
    case preOpDialysis
    case ivasReevaluation
    case labsReevaluation

    var displayName: String {
        switch self {
        case .icuBedRequired: return "Vaga de UTI"
        case .cardiacEnzymes: return "Enzimas cardíacas"
        case .preOpDialysis: return "Diálise pré-op"
        case .ivasReevaluation: return "Reavaliação de IVAS"
        case .labsReevaluation: return "Reavaliação de exames"
        }
    }

    var reportDisplayName: String {
        switch self {
        case .icuBedRequired: return "vaga de UTI necessária"
        case .cardiacEnzymes: return "seriar enzimas cardíacas pós-procedimento"
        case .preOpDialysis: return "diálise pré-procedimento recomendada"
        case .ivasReevaluation: return "reavaliação de IVAS em centro cirúrgico"
        case .labsReevaluation: return "reavaliar exames alterados"
        }
    }
}

public enum UnableReason: String, ClearanceItem {
    case poorBloodPressureControl
    case poorGlycemicControl
    case requiresCoronaryIntervention
    case requiresValvularIntervention
    case severeAnemia

    var displayName: String {
        switch self {
        case .poorBloodPressureControl: return "Controle pressórico inadequado"
        case .poorGlycemicControl: return "Controle glicêmico inadequado"
        case .requiresCoronaryIntervention: return "Necessita intervenção coronariana"
        case .requiresValvularIntervention: return "Necessita correção valvar"
        case .severeAnemia: return "Anemia grave não corrigida"
        }
    }

    var reportDisplayName: String {
        switch self {
        case .poorBloodPressureControl: return "controle pressórico inadequado"
        case .poorGlycemicControl: return "controle glicêmico inadequado"
        case .requiresCoronaryIntervention: return "necessita de intervenção coronariana prévia"
        case .requiresValvularIntervention: return "necessita de correção valvar prévia"
        case .severeAnemia: return "anemia grave não corrigida"
        }
    }
}
