import SwiftUI

struct PreanesthesiaComorbiditiesSection: View {
    @Binding var items: [PreanesthesiaItemInput]

    var body: some View {
        ForEach(sectionConfigs) { config in
            Section {
                DomainSection(config: config, items: $items)
            } header: {
                Text(config.title)
            } footer: {
                Text(config.footer)
            }
        }
    }

    private var sectionConfigs: [DomainSectionConfig] {
        let footer = "Selecione comorbidades e descreva detalhes relevantes."
        return [
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.infant.rawValue)",
                title: "Infantis",
                domain: .comorbidity,
                category: ComorbidityCategory.infant.rawValue,
                codes: InfantComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: InfantComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.pregnant.rawValue)",
                title: "Gestacionais",
                domain: .comorbidity,
                category: ComorbidityCategory.pregnant.rawValue,
                codes: PregnantComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: PregnantComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.cardiovascular.rawValue)",
                title: "Cardiovascular",
                domain: .comorbidity,
                category: ComorbidityCategory.cardiovascular.rawValue,
                codes: CardioComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: CardioComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.respiratory.rawValue)",
                title: "Respiratórias",
                domain: .comorbidity,
                category: ComorbidityCategory.respiratory.rawValue,
                codes: RespiratoryComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: RespiratoryComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.neurological.rawValue)",
                title: "Neurológicas",
                domain: .comorbidity,
                category: ComorbidityCategory.neurological.rawValue,
                codes: NeuroComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: NeuroComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.gastrointestinal.rawValue)",
                title: "Gastrointestinais",
                domain: .comorbidity,
                category: ComorbidityCategory.gastrointestinal.rawValue,
                codes: GastrointestinalComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: GastrointestinalComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.endocrinal.rawValue)",
                title: "Endócrinas",
                domain: .comorbidity,
                category: ComorbidityCategory.endocrinal.rawValue,
                codes: EndocrineComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: EndocrineComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.hematological.rawValue)",
                title: "Hematológicas",
                domain: .comorbidity,
                category: ComorbidityCategory.hematological.rawValue,
                codes: HematologicComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: HematologicComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.imunological.rawValue)",
                title: "Imunológicas",
                domain: .comorbidity,
                category: ComorbidityCategory.imunological.rawValue,
                codes: ImmunologicComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: ImmunologicComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.infectious.rawValue)",
                title: "Infecciosas",
                domain: .comorbidity,
                category: ComorbidityCategory.infectious.rawValue,
                codes: InfectiousComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: InfectiousComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.muskuloeskeletical.rawValue)",
                title: "Musculoesqueléticas",
                domain: .comorbidity,
                category: ComorbidityCategory.muskuloeskeletical.rawValue,
                codes: MusculoskeleticComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: MusculoskeleticComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.genitourinary.rawValue)",
                title: "Genitourinárias",
                domain: .comorbidity,
                category: ComorbidityCategory.genitourinary.rawValue,
                codes: GenitourinaryComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: GenitourinaryComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.gynecological.rawValue)",
                title: "Ginecológicas",
                domain: .comorbidity,
                category: ComorbidityCategory.gynecological.rawValue,
                codes: GynecologicComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: GynecologicComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.andrological.rawValue)",
                title: "Andrológicas",
                domain: .comorbidity,
                category: ComorbidityCategory.andrological.rawValue,
                codes: AndrologicComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: AndrologicComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.oncological.rawValue)",
                title: "Oncológicas",
                domain: .comorbidity,
                category: ComorbidityCategory.oncological.rawValue,
                codes: OncologicComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: OncologicComorbidityCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Comorbidade"
            ),
            DomainSectionConfig(
                id: "comorbidity-\(ComorbidityCategory.genetical.rawValue)",
                title: "Síndromes Genéticas",
                domain: .comorbidity,
                category: ComorbidityCategory.genetical.rawValue,
                codes: GeneticComorbidityCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: GeneticComorbidityCode.customCase.rawValue,
                footer: "Selecione síndrome e descreva detalhes relevantes.",
                customLabelPlaceholder: "Comorbidade"
            ),
        ]
    }
}
#Preview {
    @State var items: [PreanesthesiaItemInput] = []
    return Form {
        PreanesthesiaComorbiditiesSection(items: $items)
    }
}
