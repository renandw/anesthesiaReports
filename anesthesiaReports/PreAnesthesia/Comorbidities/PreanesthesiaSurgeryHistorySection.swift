import SwiftUI

struct PreanesthesiaSurgeryHistorySection: View {
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
        let footer = "..."
        return [
            DomainSectionConfig(
                id: "surgery-history-\(SurgeryHistoryCategory.general.rawValue)",
                title: "Cirurgia Geral",
                domain: .surgeryHistory,
                category: SurgeryHistoryCategory.general.rawValue,
                codes: GeneralSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: GeneralSurgeryHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Cirurgia"
            ),
            DomainSectionConfig(
                id: "surgery-history-\(SurgeryHistoryCategory.orthopedics.rawValue)",
                title: "Ortopedia",
                domain: .surgeryHistory,
                category: SurgeryHistoryCategory.orthopedics.rawValue,
                codes: OrtopedicSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: OrtopedicSurgeryHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Cirurgia"
            ),
            DomainSectionConfig(
                id: "surgery-history-\(SurgeryHistoryCategory.cardiac.rawValue)",
                title: "Cardíaca",
                domain: .surgeryHistory,
                category: SurgeryHistoryCategory.cardiac.rawValue,
                codes: CardiacSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: CardiacSurgeryHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Cirurgia"
            ),
            DomainSectionConfig(
                id: "surgery-history-\(SurgeryHistoryCategory.neurosurgery.rawValue)",
                title: "Neurocirurgia",
                domain: .surgeryHistory,
                category: SurgeryHistoryCategory.neurosurgery.rawValue,
                codes: NeurologicSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: NeurologicSurgeryHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Cirurgia"
            ),
            DomainSectionConfig(
                id: "surgery-history-\(SurgeryHistoryCategory.urology.rawValue)",
                title: "Urológicas",
                domain: .surgeryHistory,
                category: SurgeryHistoryCategory.urology.rawValue,
                codes: UrologicSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: UrologicSurgeryHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Cirurgia"
            ),
            DomainSectionConfig(
                id: "surgery-history-\(SurgeryHistoryCategory.gynecology.rawValue)",
                title: "Ginecológicas",
                domain: .surgeryHistory,
                category: SurgeryHistoryCategory.gynecology.rawValue,
                codes: GynecologicSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: GynecologicSurgeryHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Cirurgia"
            ),
            DomainSectionConfig(
                id: "surgery-history-\(SurgeryHistoryCategory.bucomaxillofacial.rawValue)",
                title: "Bucomaxilofaciais",
                domain: .surgeryHistory,
                category: SurgeryHistoryCategory.bucomaxillofacial.rawValue,
                codes: BucomaxillofacialSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: BucomaxillofacialSurgeryHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Cirurgia"
            ),
            DomainSectionConfig(
                id: "surgery-history-\(SurgeryHistoryCategory.ophthalmology.rawValue)",
                title: "Oftalmológicas",
                domain: .surgeryHistory,
                category: SurgeryHistoryCategory.ophthalmology.rawValue,
                codes: OphthalmologicSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: OphthalmologicSurgeryHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Cirurgia"
            ),
            DomainSectionConfig(
                id: "surgery-history-\(SurgeryHistoryCategory.headAndNeck.rawValue)",
                title: "Cabeça e Pescoço",
                domain: .surgeryHistory,
                category: SurgeryHistoryCategory.headAndNeck.rawValue,
                codes: HeadAndNeckSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: HeadAndNeckSurgeryHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Cirurgia"
            ),
            DomainSectionConfig(
                id: "surgery-history-\(SurgeryHistoryCategory.vascular.rawValue)",
                title: "Vascular",
                domain: .surgeryHistory,
                category: SurgeryHistoryCategory.vascular.rawValue,
                codes: VascularSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: VascularSurgeryHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Cirurgia"
            ),
            DomainSectionConfig(
                id: "surgery-history-\(SurgeryHistoryCategory.oncology.rawValue)",
                title: "Oncológicas",
                domain: .surgeryHistory,
                category: SurgeryHistoryCategory.oncology.rawValue,
                codes: OncologicSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: OncologicSurgeryHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Cirurgia"
            ),
            DomainSectionConfig(
                id: "surgery-history-\(SurgeryHistoryCategory.thorax.rawValue)",
                title: "Torácica",
                domain: .surgeryHistory,
                category: SurgeryHistoryCategory.thorax.rawValue,
                codes: ThoracicSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: ThoracicSurgeryHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Cirurgia"
            ),
            DomainSectionConfig(
                id: "surgery-history-\(SurgeryHistoryCategory.narcose.rawValue)",
                title: "Exames sob narcose",
                domain: .surgeryHistory,
                category: SurgeryHistoryCategory.narcose.rawValue,
                codes: NarcosisSurgeryHistoryCode.allCases.filter { $0 != .custom }.map { $0.option },
                customCodeRawValue: NarcosisSurgeryHistoryCode.customCase.rawValue,
                footer: footer,
                customLabelPlaceholder: "Cirurgia"
            ),
        ]
    }
}

#Preview {
    @State var items: [PreanesthesiaItemInput] = []
    return Form {
        PreanesthesiaSurgeryHistorySection(items: $items)
    }
}
